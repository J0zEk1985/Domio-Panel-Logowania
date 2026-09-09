-- Layer 2: RLS, storage object policies, and SECURITY DEFINER RPCs.
-- Privileged logic lives in schema private (not exposed via PostgREST).
-- Public wrappers are thin delegates granted to authenticated.

-- ---------------------------------------------------------------------------
-- Private schema
-- ---------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS private;

REVOKE ALL ON SCHEMA private FROM PUBLIC;
REVOKE ALL ON SCHEMA private FROM anon, authenticated;
GRANT USAGE ON SCHEMA private TO postgres, service_role;

-- ---------------------------------------------------------------------------
-- Guards and helpers
-- ---------------------------------------------------------------------------

CREATE FUNCTION private.equipment_set_rpc_flag()
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  PERFORM set_config('app.equipment_rpc', '1', true);
END;
$$;

CREATE FUNCTION private.equipment_require_actor()
RETURNS uuid
LANGUAGE plpgsql
STABLE
SET search_path TO 'public'
AS $$
DECLARE
  v_actor uuid := (SELECT auth.uid());
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'EQUIPMENT_AUTH_REQUIRED';
  END IF;
  RETURN v_actor;
END;
$$;

CREATE FUNCTION private.equipment_normalize_photo_urls(p_urls text[])
RETURNS text[]
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  SELECT COALESCE(
    ARRAY(
      SELECT btrim(u)
      FROM unnest(COALESCE(p_urls, '{}'::text[])) AS u
      WHERE btrim(COALESCE(u, '')) <> ''
    ),
    '{}'::text[]
  );
$$;

CREATE FUNCTION private.equipment_assert_active_member(p_org_id uuid, p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
STABLE
SET search_path TO 'public'
AS $$
BEGIN
  IF p_org_id IS NULL OR p_user_id IS NULL THEN
    RAISE EXCEPTION 'EQUIPMENT_FORBIDDEN';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.memberships m
    WHERE m.org_id = p_org_id
      AND m.user_id = p_user_id
      AND COALESCE(m.is_active, true) = true
  ) THEN
    RAISE EXCEPTION 'EQUIPMENT_WORKER_NOT_IN_ORG';
  END IF;
END;
$$;

CREATE FUNCTION private.equipment_apply_protocol_resolution(
  p_protocol public.equipment_protocols,
  p_terminal_status text
)
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public', 'private'
AS $$
BEGIN
  PERFORM private.equipment_set_rpc_flag();

  IF p_protocol.kind = 'asset' THEN
    IF p_terminal_status = 'accepted' AND p_protocol.direction = 'handover' THEN
      UPDATE public.equipment_assets
      SET status = 'assigned'
      WHERE id = p_protocol.asset_id;
    ELSIF p_terminal_status = 'accepted' AND p_protocol.direction = 'return' THEN
      UPDATE public.equipment_assets
      SET status = 'available', current_holder_id = NULL
      WHERE id = p_protocol.asset_id;
    ELSIF p_protocol.direction = 'handover' THEN
      UPDATE public.equipment_assets
      SET status = 'available', current_holder_id = NULL
      WHERE id = p_protocol.asset_id;
    ELSE
      UPDATE public.equipment_assets
      SET status = 'assigned', current_holder_id = p_protocol.worker_id
      WHERE id = p_protocol.asset_id;
    END IF;
  ELSE
    IF p_terminal_status = 'accepted' AND p_protocol.direction = 'handover' THEN
      UPDATE public.staff_equipment
      SET status = 'assigned', assigned_at = now(), returned_at = NULL
      WHERE id = p_protocol.staff_equipment_id;
    ELSIF p_terminal_status = 'accepted' AND p_protocol.direction = 'return' THEN
      UPDATE public.staff_equipment
      SET status = 'returned', returned_at = now()
      WHERE id = p_protocol.staff_equipment_id;
    ELSIF p_protocol.direction = 'handover' THEN
      -- Incomplete handover: keep the row for protocol FK, mark as not in possession.
      UPDATE public.staff_equipment
      SET status = 'returned', returned_at = now()
      WHERE id = p_protocol.staff_equipment_id;
    ELSE
      UPDATE public.staff_equipment
      SET status = 'assigned', returned_at = NULL
      WHERE id = p_protocol.staff_equipment_id;
    END IF;
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- Triggers: lifecycle columns and protocol rows only via RPC
-- ---------------------------------------------------------------------------

CREATE FUNCTION private.tg_equipment_lifecycle_via_rpc()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF current_setting('app.equipment_rpc', true) = '1' THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  IF TG_TABLE_NAME = 'equipment_assets' THEN
    IF TG_OP = 'INSERT' THEN
      IF NEW.status IS DISTINCT FROM 'available' OR NEW.current_holder_id IS NOT NULL THEN
        RAISE EXCEPTION 'EQUIPMENT_STATUS_VIA_RPC';
      END IF;
    ELSIF TG_OP = 'UPDATE' THEN
      IF NEW.status IS DISTINCT FROM OLD.status
         OR NEW.current_holder_id IS DISTINCT FROM OLD.current_holder_id THEN
        RAISE EXCEPTION 'EQUIPMENT_STATUS_VIA_RPC';
      END IF;
    END IF;
  ELSIF TG_TABLE_NAME = 'staff_equipment' THEN
    IF TG_OP = 'INSERT' THEN
      -- Legacy UI still inserts assigned keys/cards directly.
      IF NEW.status IS DISTINCT FROM 'assigned' THEN
        RAISE EXCEPTION 'EQUIPMENT_STATUS_VIA_RPC';
      END IF;
    ELSIF TG_OP = 'UPDATE' THEN
      IF NEW.status IS DISTINCT FROM OLD.status
         OR NEW.returned_at IS DISTINCT FROM OLD.returned_at THEN
        RAISE EXCEPTION 'EQUIPMENT_STATUS_VIA_RPC';
      END IF;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE FUNCTION private.tg_equipment_protocols_via_rpc()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF current_setting('app.equipment_rpc', true) = '1' THEN
    RETURN COALESCE(NEW, OLD);
  END IF;
  RAISE EXCEPTION 'EQUIPMENT_PROTOCOL_VIA_RPC';
END;
$$;

CREATE TRIGGER equipment_assets_lifecycle_via_rpc
  BEFORE INSERT OR UPDATE ON public.equipment_assets
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_equipment_lifecycle_via_rpc();

CREATE TRIGGER staff_equipment_lifecycle_via_rpc
  BEFORE INSERT OR UPDATE ON public.staff_equipment
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_equipment_lifecycle_via_rpc();

CREATE TRIGGER equipment_protocols_writes_via_rpc
  BEFORE INSERT OR UPDATE OR DELETE ON public.equipment_protocols
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_equipment_protocols_via_rpc();

-- ---------------------------------------------------------------------------
-- Core RPCs (private)
-- ---------------------------------------------------------------------------

CREATE FUNCTION private.initiate_equipment_handover(
  p_org_id uuid,
  p_worker_id uuid,
  p_kind text,
  p_asset_id uuid DEFAULT NULL,
  p_key_name text DEFAULT NULL,
  p_key_type text DEFAULT 'other',
  p_condition_notes text DEFAULT NULL,
  p_photo_urls text[] DEFAULT '{}'::text[]
)
RETURNS public.equipment_protocols
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private'
AS $$
DECLARE
  v_actor uuid := private.equipment_require_actor();
  v_protocol public.equipment_protocols;
  v_staff_id uuid;
  v_key_type text := lower(btrim(COALESCE(p_key_type, 'other')));
BEGIN
  IF NOT public.is_org_management(p_org_id) THEN
    RAISE EXCEPTION 'EQUIPMENT_FORBIDDEN';
  END IF;

  PERFORM private.equipment_assert_active_member(p_org_id, p_worker_id);

  IF p_kind NOT IN ('asset', 'key_card') THEN
    RAISE EXCEPTION 'EQUIPMENT_INVALID_KIND';
  END IF;

  PERFORM private.equipment_set_rpc_flag();

  IF p_kind = 'asset' THEN
    IF p_asset_id IS NULL THEN
      RAISE EXCEPTION 'EQUIPMENT_ASSET_REQUIRED';
    END IF;

    UPDATE public.equipment_assets
    SET status = 'pending_handover', current_holder_id = p_worker_id
    WHERE id = p_asset_id
      AND org_id = p_org_id
      AND status = 'available'
      AND current_holder_id IS NULL
    RETURNING id INTO v_staff_id;

    IF v_staff_id IS NULL THEN
      RAISE EXCEPTION 'EQUIPMENT_INVALID_STATE';
    END IF;

    INSERT INTO public.equipment_protocols (
      org_id, kind, asset_id, worker_id, direction, status,
      initiated_by, condition_notes, photo_urls
    ) VALUES (
      p_org_id, 'asset', p_asset_id, p_worker_id, 'handover', 'pending',
      v_actor, NULLIF(btrim(COALESCE(p_condition_notes, '')), ''),
      private.equipment_normalize_photo_urls(p_photo_urls)
    )
    RETURNING * INTO v_protocol;
  ELSE
    IF btrim(COALESCE(p_key_name, '')) = '' THEN
      RAISE EXCEPTION 'EQUIPMENT_NAME_REQUIRED';
    END IF;
    IF v_key_type NOT IN ('key', 'card', 'other') THEN
      RAISE EXCEPTION 'EQUIPMENT_INVALID_TYPE';
    END IF;

    INSERT INTO public.staff_equipment (
      org_id, staff_id, type, name, status, assigned_at, created_by
    ) VALUES (
      p_org_id, p_worker_id, v_key_type, btrim(p_key_name),
      'pending_handover', now(), v_actor
    )
    RETURNING id INTO v_staff_id;

    INSERT INTO public.equipment_protocols (
      org_id, kind, staff_equipment_id, worker_id, direction, status,
      initiated_by, condition_notes, photo_urls
    ) VALUES (
      p_org_id, 'key_card', v_staff_id, p_worker_id, 'handover', 'pending',
      v_actor, NULLIF(btrim(COALESCE(p_condition_notes, '')), ''),
      private.equipment_normalize_photo_urls(p_photo_urls)
    )
    RETURNING * INTO v_protocol;
  END IF;

  RETURN v_protocol;
END;
$$;

CREATE FUNCTION private.initiate_equipment_return(
  p_kind text,
  p_asset_id uuid DEFAULT NULL,
  p_staff_equipment_id uuid DEFAULT NULL,
  p_condition_notes text DEFAULT NULL,
  p_photo_urls text[] DEFAULT '{}'::text[]
)
RETURNS public.equipment_protocols
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private'
AS $$
DECLARE
  v_actor uuid := private.equipment_require_actor();
  v_protocol public.equipment_protocols;
  v_org uuid;
  v_worker uuid;
  v_mgmt boolean;
BEGIN
  IF p_kind NOT IN ('asset', 'key_card') THEN
    RAISE EXCEPTION 'EQUIPMENT_INVALID_KIND';
  END IF;

  PERFORM private.equipment_set_rpc_flag();

  IF p_kind = 'asset' THEN
    IF p_asset_id IS NULL THEN
      RAISE EXCEPTION 'EQUIPMENT_ASSET_REQUIRED';
    END IF;

    SELECT org_id, current_holder_id
    INTO v_org, v_worker
    FROM public.equipment_assets
    WHERE id = p_asset_id
    FOR UPDATE;

    IF v_org IS NULL THEN
      RAISE EXCEPTION 'EQUIPMENT_NOT_FOUND';
    END IF;

    v_mgmt := public.is_org_management(v_org);
    IF NOT v_mgmt AND v_actor IS DISTINCT FROM v_worker THEN
      RAISE EXCEPTION 'EQUIPMENT_FORBIDDEN';
    END IF;
    IF v_worker IS NULL THEN
      RAISE EXCEPTION 'EQUIPMENT_INVALID_STATE';
    END IF;

    UPDATE public.equipment_assets
    SET status = 'pending_return'
    WHERE id = p_asset_id
      AND status = 'assigned'
      AND current_holder_id = v_worker;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'EQUIPMENT_INVALID_STATE';
    END IF;

    INSERT INTO public.equipment_protocols (
      org_id, kind, asset_id, worker_id, direction, status,
      initiated_by, condition_notes, photo_urls
    ) VALUES (
      v_org, 'asset', p_asset_id, v_worker, 'return', 'pending',
      v_actor, NULLIF(btrim(COALESCE(p_condition_notes, '')), ''),
      private.equipment_normalize_photo_urls(p_photo_urls)
    )
    RETURNING * INTO v_protocol;
  ELSE
    IF p_staff_equipment_id IS NULL THEN
      RAISE EXCEPTION 'EQUIPMENT_ITEM_REQUIRED';
    END IF;

    SELECT org_id, staff_id
    INTO v_org, v_worker
    FROM public.staff_equipment
    WHERE id = p_staff_equipment_id
    FOR UPDATE;

    IF v_org IS NULL THEN
      RAISE EXCEPTION 'EQUIPMENT_NOT_FOUND';
    END IF;

    v_mgmt := public.is_org_management(v_org);
    IF NOT v_mgmt AND v_actor IS DISTINCT FROM v_worker THEN
      RAISE EXCEPTION 'EQUIPMENT_FORBIDDEN';
    END IF;

    UPDATE public.staff_equipment
    SET status = 'pending_return'
    WHERE id = p_staff_equipment_id
      AND status = 'assigned'
      AND staff_id = v_worker;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'EQUIPMENT_INVALID_STATE';
    END IF;

    INSERT INTO public.equipment_protocols (
      org_id, kind, staff_equipment_id, worker_id, direction, status,
      initiated_by, condition_notes, photo_urls
    ) VALUES (
      v_org, 'key_card', p_staff_equipment_id, v_worker, 'return', 'pending',
      v_actor, NULLIF(btrim(COALESCE(p_condition_notes, '')), ''),
      private.equipment_normalize_photo_urls(p_photo_urls)
    )
    RETURNING * INTO v_protocol;
  END IF;

  RETURN v_protocol;
END;
$$;

CREATE FUNCTION private.respond_equipment_protocol(
  p_protocol_id uuid,
  p_accept boolean,
  p_condition_notes text DEFAULT NULL,
  p_photo_urls text[] DEFAULT NULL
)
RETURNS public.equipment_protocols
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private'
AS $$
DECLARE
  v_actor uuid := private.equipment_require_actor();
  v_protocol public.equipment_protocols;
  v_is_mgmt boolean;
  v_is_worker boolean;
  v_is_initiator boolean;
  v_is_counterparty boolean;
  v_terminal text;
BEGIN
  PERFORM private.equipment_set_rpc_flag();

  SELECT *
  INTO v_protocol
  FROM public.equipment_protocols
  WHERE id = p_protocol_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'EQUIPMENT_NOT_FOUND';
  END IF;

  IF v_protocol.status IS DISTINCT FROM 'pending' THEN
    RAISE EXCEPTION 'EQUIPMENT_INVALID_STATE';
  END IF;

  v_is_mgmt := public.is_org_management(v_protocol.org_id);
  v_is_worker := v_actor = v_protocol.worker_id;
  v_is_initiator := v_actor = v_protocol.initiated_by;
  v_is_counterparty := (v_is_worker OR v_is_mgmt) AND NOT v_is_initiator;

  -- Handover: only the worker accepts/rejects. Return: the other party.
  IF v_protocol.direction = 'handover' THEN
    IF NOT v_is_worker OR v_is_initiator THEN
      RAISE EXCEPTION 'EQUIPMENT_NOT_COUNTERPARTY';
    END IF;
  ELSE
    IF NOT v_is_counterparty THEN
      RAISE EXCEPTION 'EQUIPMENT_NOT_COUNTERPARTY';
    END IF;
  END IF;

  v_terminal := CASE WHEN p_accept THEN 'accepted' ELSE 'rejected' END;

  UPDATE public.equipment_protocols
  SET
    status = v_terminal,
    responded_by = v_actor,
    responded_at = now(),
    condition_notes = COALESCE(
      NULLIF(btrim(COALESCE(p_condition_notes, '')), ''),
      condition_notes
    ),
    photo_urls = CASE
      WHEN p_photo_urls IS NULL THEN photo_urls
      ELSE photo_urls || private.equipment_normalize_photo_urls(p_photo_urls)
    END
  WHERE id = p_protocol_id
  RETURNING * INTO v_protocol;

  PERFORM private.equipment_apply_protocol_resolution(v_protocol, v_terminal);
  RETURN v_protocol;
END;
$$;

CREATE FUNCTION private.cancel_equipment_protocol(p_protocol_id uuid)
RETURNS public.equipment_protocols
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private'
AS $$
DECLARE
  v_actor uuid := private.equipment_require_actor();
  v_protocol public.equipment_protocols;
BEGIN
  PERFORM private.equipment_set_rpc_flag();

  SELECT *
  INTO v_protocol
  FROM public.equipment_protocols
  WHERE id = p_protocol_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'EQUIPMENT_NOT_FOUND';
  END IF;

  IF v_protocol.status IS DISTINCT FROM 'pending' THEN
    RAISE EXCEPTION 'EQUIPMENT_INVALID_STATE';
  END IF;

  IF v_actor IS DISTINCT FROM v_protocol.initiated_by
     AND NOT public.is_org_management(v_protocol.org_id) THEN
    RAISE EXCEPTION 'EQUIPMENT_FORBIDDEN';
  END IF;

  UPDATE public.equipment_protocols
  SET
    status = 'cancelled',
    responded_by = v_actor,
    responded_at = now()
  WHERE id = p_protocol_id
  RETURNING * INTO v_protocol;

  PERFORM private.equipment_apply_protocol_resolution(v_protocol, 'cancelled');
  RETURN v_protocol;
END;
$$;

CREATE FUNCTION private.set_equipment_protocol_evidence(
  p_protocol_id uuid,
  p_condition_notes text DEFAULT NULL,
  p_photo_urls text[] DEFAULT NULL
)
RETURNS public.equipment_protocols
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private'
AS $$
DECLARE
  v_actor uuid := private.equipment_require_actor();
  v_protocol public.equipment_protocols;
BEGIN
  PERFORM private.equipment_set_rpc_flag();

  SELECT *
  INTO v_protocol
  FROM public.equipment_protocols
  WHERE id = p_protocol_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'EQUIPMENT_NOT_FOUND';
  END IF;

  IF v_protocol.status IS DISTINCT FROM 'pending' THEN
    RAISE EXCEPTION 'EQUIPMENT_INVALID_STATE';
  END IF;

  IF v_actor IS DISTINCT FROM v_protocol.initiated_by
     AND v_actor IS DISTINCT FROM v_protocol.worker_id
     AND NOT public.is_org_management(v_protocol.org_id) THEN
    RAISE EXCEPTION 'EQUIPMENT_FORBIDDEN';
  END IF;

  UPDATE public.equipment_protocols
  SET
    condition_notes = COALESCE(
      NULLIF(btrim(COALESCE(p_condition_notes, '')), ''),
      condition_notes
    ),
    photo_urls = CASE
      WHEN p_photo_urls IS NULL THEN photo_urls
      ELSE private.equipment_normalize_photo_urls(p_photo_urls)
    END
  WHERE id = p_protocol_id
  RETURNING * INTO v_protocol;

  RETURN v_protocol;
END;
$$;

CREATE FUNCTION private.retire_equipment_asset(p_asset_id uuid)
RETURNS public.equipment_assets
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private'
AS $$
DECLARE
  v_actor uuid := private.equipment_require_actor();
  v_asset public.equipment_assets;
BEGIN
  SELECT * INTO v_asset FROM public.equipment_assets WHERE id = p_asset_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'EQUIPMENT_NOT_FOUND';
  END IF;
  IF NOT public.is_org_management(v_asset.org_id) THEN
    RAISE EXCEPTION 'EQUIPMENT_FORBIDDEN';
  END IF;
  IF v_asset.status IS DISTINCT FROM 'available' THEN
    RAISE EXCEPTION 'EQUIPMENT_INVALID_STATE';
  END IF;

  PERFORM private.equipment_set_rpc_flag();

  UPDATE public.equipment_assets
  SET status = 'retired'
  WHERE id = p_asset_id
  RETURNING * INTO v_asset;

  RETURN v_asset;
END;
$$;

-- ---------------------------------------------------------------------------
-- Storage path helper
-- ---------------------------------------------------------------------------

CREATE FUNCTION private.can_access_equipment_protocol_object(
  p_object_name text,
  p_write boolean DEFAULT false
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'storage'
AS $$
DECLARE
  v_actor uuid := (SELECT auth.uid());
  v_parts text[];
  v_org uuid;
  v_protocol_id uuid;
  v_protocol public.equipment_protocols;
BEGIN
  IF v_actor IS NULL OR p_object_name IS NULL THEN
    RETURN false;
  END IF;

  v_parts := storage.foldername(p_object_name);
  IF array_length(v_parts, 1) IS NULL OR array_length(v_parts, 1) < 2 THEN
    RETURN false;
  END IF;

  BEGIN
    v_org := v_parts[1]::uuid;
    v_protocol_id := v_parts[2]::uuid;
  EXCEPTION WHEN invalid_text_representation THEN
    RETURN false;
  END;

  SELECT * INTO v_protocol
  FROM public.equipment_protocols
  WHERE id = v_protocol_id
    AND org_id = v_org;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  IF p_write AND v_protocol.status IS DISTINCT FROM 'pending' THEN
    RETURN false;
  END IF;

  RETURN
    public.is_org_management(v_protocol.org_id)
    OR v_actor = v_protocol.worker_id
    OR v_actor = v_protocol.initiated_by;
END;
$$;

REVOKE ALL ON FUNCTION private.equipment_set_rpc_flag() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.equipment_require_actor() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.equipment_normalize_photo_urls(text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.equipment_assert_active_member(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.equipment_apply_protocol_resolution(public.equipment_protocols, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.tg_equipment_lifecycle_via_rpc() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.tg_equipment_protocols_via_rpc() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.initiate_equipment_handover(uuid, uuid, text, uuid, text, text, text, text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.initiate_equipment_return(text, uuid, uuid, text, text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.respond_equipment_protocol(uuid, boolean, text, text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.cancel_equipment_protocol(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.set_equipment_protocol_evidence(uuid, text, text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.retire_equipment_asset(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.can_access_equipment_protocol_object(text, boolean) FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- Public wrappers (PostgREST)
-- ---------------------------------------------------------------------------

CREATE FUNCTION public.initiate_equipment_handover(
  p_org_id uuid,
  p_worker_id uuid,
  p_kind text,
  p_asset_id uuid DEFAULT NULL,
  p_key_name text DEFAULT NULL,
  p_key_type text DEFAULT 'other',
  p_condition_notes text DEFAULT NULL,
  p_photo_urls text[] DEFAULT '{}'::text[]
)
RETURNS public.equipment_protocols
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'private', 'public'
AS $$
  SELECT * FROM private.initiate_equipment_handover(
    p_org_id, p_worker_id, p_kind, p_asset_id, p_key_name, p_key_type,
    p_condition_notes, p_photo_urls
  );
$$;

CREATE FUNCTION public.initiate_equipment_return(
  p_kind text,
  p_asset_id uuid DEFAULT NULL,
  p_staff_equipment_id uuid DEFAULT NULL,
  p_condition_notes text DEFAULT NULL,
  p_photo_urls text[] DEFAULT '{}'::text[]
)
RETURNS public.equipment_protocols
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'private', 'public'
AS $$
  SELECT * FROM private.initiate_equipment_return(
    p_kind, p_asset_id, p_staff_equipment_id, p_condition_notes, p_photo_urls
  );
$$;

CREATE FUNCTION public.respond_equipment_protocol(
  p_protocol_id uuid,
  p_accept boolean,
  p_condition_notes text DEFAULT NULL,
  p_photo_urls text[] DEFAULT NULL
)
RETURNS public.equipment_protocols
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'private', 'public'
AS $$
  SELECT * FROM private.respond_equipment_protocol(
    p_protocol_id, p_accept, p_condition_notes, p_photo_urls
  );
$$;

CREATE FUNCTION public.cancel_equipment_protocol(p_protocol_id uuid)
RETURNS public.equipment_protocols
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'private', 'public'
AS $$
  SELECT * FROM private.cancel_equipment_protocol(p_protocol_id);
$$;

CREATE FUNCTION public.set_equipment_protocol_evidence(
  p_protocol_id uuid,
  p_condition_notes text DEFAULT NULL,
  p_photo_urls text[] DEFAULT NULL
)
RETURNS public.equipment_protocols
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'private', 'public'
AS $$
  SELECT * FROM private.set_equipment_protocol_evidence(
    p_protocol_id, p_condition_notes, p_photo_urls
  );
$$;

CREATE FUNCTION public.retire_equipment_asset(p_asset_id uuid)
RETURNS public.equipment_assets
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'private', 'public'
AS $$
  SELECT * FROM private.retire_equipment_asset(p_asset_id);
$$;

CREATE FUNCTION public.can_access_equipment_protocol_object(
  p_object_name text,
  p_write boolean DEFAULT false
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'private', 'public'
AS $$
  SELECT private.can_access_equipment_protocol_object(p_object_name, p_write);
$$;

COMMENT ON FUNCTION public.initiate_equipment_handover(uuid, uuid, text, uuid, text, text, text, text[]) IS
  'Management starts a two-sided handover protocol for a company tool or a key/card.';
COMMENT ON FUNCTION public.initiate_equipment_return(text, uuid, uuid, text, text[]) IS
  'Management or the current holder starts a two-sided return protocol.';
COMMENT ON FUNCTION public.respond_equipment_protocol(uuid, boolean, text, text[]) IS
  'Counterparty accepts or rejects a pending equipment protocol.';
COMMENT ON FUNCTION public.cancel_equipment_protocol(uuid) IS
  'Initiator or management cancels a pending protocol and reverts item state.';
COMMENT ON FUNCTION public.set_equipment_protocol_evidence(uuid, text, text[]) IS
  'Sets condition notes and photo URLs on a pending protocol.';
COMMENT ON FUNCTION public.retire_equipment_asset(uuid) IS
  'Management retires an available company tool.';

REVOKE ALL ON FUNCTION public.initiate_equipment_handover(uuid, uuid, text, uuid, text, text, text, text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.initiate_equipment_return(text, uuid, uuid, text, text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.respond_equipment_protocol(uuid, boolean, text, text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cancel_equipment_protocol(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.set_equipment_protocol_evidence(uuid, text, text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.retire_equipment_asset(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_access_equipment_protocol_object(text, boolean) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.initiate_equipment_handover(uuid, uuid, text, uuid, text, text, text, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.initiate_equipment_return(text, uuid, uuid, text, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.respond_equipment_protocol(uuid, boolean, text, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_equipment_protocol(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_equipment_protocol_evidence(uuid, text, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.retire_equipment_asset(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_access_equipment_protocol_object(text, boolean) TO authenticated;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

CREATE POLICY equipment_assets_select_management
  ON public.equipment_assets
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_org_management(org_id)));

CREATE POLICY equipment_assets_select_worker
  ON public.equipment_assets
  FOR SELECT
  TO authenticated
  USING (
    current_holder_id = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1
      FROM public.equipment_protocols p
      WHERE p.asset_id = equipment_assets.id
        AND (
          p.worker_id = (SELECT auth.uid())
          OR p.initiated_by = (SELECT auth.uid())
        )
    )
  );

CREATE POLICY equipment_assets_insert_management
  ON public.equipment_assets
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT public.is_org_management(org_id)));

CREATE POLICY equipment_assets_update_management
  ON public.equipment_assets
  FOR UPDATE
  TO authenticated
  USING ((SELECT public.is_org_management(org_id)))
  WITH CHECK ((SELECT public.is_org_management(org_id)));

CREATE POLICY equipment_protocols_select_management
  ON public.equipment_protocols
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_org_management(org_id)));

CREATE POLICY equipment_protocols_select_party
  ON public.equipment_protocols
  FOR SELECT
  TO authenticated
  USING (
    worker_id = (SELECT auth.uid())
    OR initiated_by = (SELECT auth.uid())
  );

CREATE POLICY staff_equipment_select_worker
  ON public.staff_equipment
  FOR SELECT
  TO authenticated
  USING (staff_id = (SELECT auth.uid()));

-- ---------------------------------------------------------------------------
-- Storage object policies (upsert needs INSERT + SELECT + UPDATE)
-- ---------------------------------------------------------------------------

CREATE POLICY equipment_protocols_storage_select
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'equipment-protocols'
    AND (SELECT public.can_access_equipment_protocol_object(name, false))
  );

CREATE POLICY equipment_protocols_storage_insert
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'equipment-protocols'
    AND (SELECT public.can_access_equipment_protocol_object(name, true))
  );

CREATE POLICY equipment_protocols_storage_update
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'equipment-protocols'
    AND (SELECT public.can_access_equipment_protocol_object(name, true))
  )
  WITH CHECK (
    bucket_id = 'equipment-protocols'
    AND (SELECT public.can_access_equipment_protocol_object(name, true))
  );

CREATE POLICY equipment_protocols_storage_delete
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'equipment-protocols'
    AND (SELECT public.can_access_equipment_protocol_object(name, true))
  );
