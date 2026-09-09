-- Keep coordinator condition/photos intact on respond.
-- Worker (counterparty) may only accept or reject with a required reason.
-- Persist handover condition notes onto the company asset.

ALTER TABLE public.equipment_protocols
  ADD COLUMN IF NOT EXISTS rejection_reason text;

ALTER TABLE public.equipment_protocols
  DROP CONSTRAINT IF EXISTS equipment_protocols_rejection_reason_only_rejected;

ALTER TABLE public.equipment_protocols
  ADD CONSTRAINT equipment_protocols_rejection_reason_only_rejected CHECK (
    rejection_reason IS NULL OR status = 'rejected'
  );

ALTER TABLE public.equipment_protocols
  DROP CONSTRAINT IF EXISTS equipment_protocols_rejection_reason_len;

ALTER TABLE public.equipment_protocols
  ADD CONSTRAINT equipment_protocols_rejection_reason_len CHECK (
    rejection_reason IS NULL OR char_length(rejection_reason) <= 2000
  );

COMMENT ON COLUMN public.equipment_protocols.rejection_reason IS
  'Required when status is rejected (enforced by RPC). Coordinator condition_notes stay unchanged.';

CREATE INDEX IF NOT EXISTS equipment_protocols_org_rejected_idx
  ON public.equipment_protocols (org_id, responded_at DESC)
  WHERE status = 'rejected';

CREATE OR REPLACE FUNCTION private.initiate_equipment_handover(
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
  v_notes text := NULLIF(btrim(COALESCE(p_condition_notes, '')), '');
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
    SET
      status = 'pending_handover',
      current_holder_id = p_worker_id,
      notes = v_notes
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
      v_actor, v_notes,
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
      v_actor, v_notes,
      private.equipment_normalize_photo_urls(p_photo_urls)
    )
    RETURNING * INTO v_protocol;
  END IF;

  RETURN v_protocol;
END;
$$;

CREATE OR REPLACE FUNCTION private.set_equipment_protocol_evidence(
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

CREATE OR REPLACE FUNCTION private.can_access_equipment_protocol_object(
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

  IF p_write THEN
    IF v_protocol.status IS DISTINCT FROM 'pending' THEN
      RETURN false;
    END IF;
    RETURN
      public.is_org_management(v_protocol.org_id)
      OR v_actor = v_protocol.initiated_by;
  END IF;

  RETURN
    public.is_org_management(v_protocol.org_id)
    OR v_actor = v_protocol.worker_id
    OR v_actor = v_protocol.initiated_by;
END;
$$;

DROP FUNCTION IF EXISTS public.respond_equipment_protocol(uuid, boolean, text, text[]);
DROP FUNCTION IF EXISTS private.respond_equipment_protocol(uuid, boolean, text, text[]);

CREATE FUNCTION private.respond_equipment_protocol(
  p_protocol_id uuid,
  p_accept boolean,
  p_condition_notes text DEFAULT NULL,
  p_photo_urls text[] DEFAULT NULL,
  p_rejection_reason text DEFAULT NULL
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
  v_reason text;
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

  IF p_accept THEN
    UPDATE public.equipment_protocols
    SET
      status = 'accepted',
      responded_by = v_actor,
      responded_at = now()
    WHERE id = p_protocol_id
    RETURNING * INTO v_protocol;
  ELSE
    v_reason := NULLIF(btrim(COALESCE(p_rejection_reason, p_condition_notes, '')), '');
    IF v_reason IS NULL THEN
      RAISE EXCEPTION 'EQUIPMENT_REJECTION_REASON_REQUIRED';
    END IF;
    IF char_length(v_reason) > 2000 THEN
      RAISE EXCEPTION 'EQUIPMENT_NOTES_TOO_LONG';
    END IF;

    UPDATE public.equipment_protocols
    SET
      status = 'rejected',
      responded_by = v_actor,
      responded_at = now(),
      rejection_reason = v_reason
    WHERE id = p_protocol_id
    RETURNING * INTO v_protocol;
  END IF;

  PERFORM private.equipment_apply_protocol_resolution(v_protocol, v_terminal);
  RETURN v_protocol;
END;
$$;

CREATE FUNCTION public.respond_equipment_protocol(
  p_protocol_id uuid,
  p_accept boolean,
  p_condition_notes text DEFAULT NULL,
  p_photo_urls text[] DEFAULT NULL,
  p_rejection_reason text DEFAULT NULL
)
RETURNS public.equipment_protocols
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'private', 'public'
AS $$
  SELECT * FROM private.respond_equipment_protocol(
    p_protocol_id, p_accept, p_condition_notes, p_photo_urls, p_rejection_reason
  );
$$;

COMMENT ON FUNCTION public.respond_equipment_protocol(uuid, boolean, text, text[], text) IS
  'Counterparty accepts (read-only) or rejects with a required reason. Does not alter coordinator condition notes or photos.';

REVOKE ALL ON FUNCTION public.respond_equipment_protocol(uuid, boolean, text, text[], text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.respond_equipment_protocol(uuid, boolean, text, text[], text) TO authenticated;
REVOKE ALL ON FUNCTION private.respond_equipment_protocol(uuid, boolean, text, text[], text) FROM PUBLIC, anon, authenticated;
