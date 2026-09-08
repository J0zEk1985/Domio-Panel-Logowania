-- Dispatcher-forced next job + immutable GPS override audit.
-- Layer 1–3: columns, RLS-enforced triggers, RPC.

ALTER TABLE public.property_issues
  ADD COLUMN IF NOT EXISTS dispatcher_forced_next boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS dispatcher_forced_at timestamptz,
  ADD COLUMN IF NOT EXISTS dispatcher_forced_by uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS gps_start_override boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS gps_start_override_at timestamptz,
  ADD COLUMN IF NOT EXISTS gps_start_override_by uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS gps_start_override_distance_m numeric,
  ADD COLUMN IF NOT EXISTS gps_start_lat double precision,
  ADD COLUMN IF NOT EXISTS gps_start_lng double precision;

COMMENT ON COLUMN public.property_issues.dispatcher_forced_next IS
  'When true, this is the next job the assigned technician must start.';
COMMENT ON COLUMN public.property_issues.gps_start_override IS
  'Immutable audit: technician started despite failed/missing GPS verification.';

CREATE UNIQUE INDEX IF NOT EXISTS property_issues_one_forced_next_per_tech
  ON public.property_issues (org_id, assigned_staff_id)
  WHERE dispatcher_forced_next = true
    AND assigned_staff_id IS NOT NULL
    AND status IN ('open', 'in_progress', 'waiting_for_parts');

ALTER TABLE public.issue_lifecycle_events
  DROP CONSTRAINT IF EXISTS issue_lifecycle_events_event_type_check;

ALTER TABLE public.issue_lifecycle_events
  ADD CONSTRAINT issue_lifecycle_events_event_type_check
  CHECK (event_type = ANY (ARRAY[
    'claimed'::text,
    'started'::text,
    'cancel_requested'::text,
    'cancelled'::text,
    'transfer_requested'::text,
    'transfer_accepted'::text,
    'transfer_rejected'::text,
    'gps_start_override'::text,
    'dispatcher_forced'::text,
    'dispatcher_unforced'::text
  ]));

CREATE OR REPLACE FUNCTION public.merge_immutable_issue_comments(p_old jsonb, p_new jsonb)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $$
  WITH old_imm AS (
    SELECT value AS item
    FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(p_old) = 'array' THEN p_old ELSE '[]'::jsonb END
    )
    WHERE COALESCE((value ->> 'immutable')::boolean, false)
  ),
  new_arr AS (
    SELECT value AS item
    FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(p_new) = 'array' THEN p_new ELSE '[]'::jsonb END
    )
  ),
  new_without_imm AS (
    SELECT n.item
    FROM new_arr n
    WHERE NOT EXISTS (
      SELECT 1
      FROM old_imm o
      WHERE COALESCE(o.item ->> 'id', '') <> ''
        AND (o.item ->> 'id') = (n.item ->> 'id')
    )
  )
  SELECT COALESCE((SELECT jsonb_agg(item) FROM old_imm), '[]'::jsonb)
      || COALESCE((SELECT jsonb_agg(item) FROM new_without_imm), '[]'::jsonb);
$$;

COMMENT ON FUNCTION public.merge_immutable_issue_comments(jsonb, jsonb) IS
  'Re-inserts immutable internal comments if a client tries to drop or edit them.';

REVOKE ALL ON FUNCTION public.merge_immutable_issue_comments(jsonb, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.merge_immutable_issue_comments(jsonb, jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION public.technician_has_other_forced_issue(
  p_org_id uuid,
  p_staff_id uuid,
  p_except_issue_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.property_issues i
    WHERE i.org_id = p_org_id
      AND i.assigned_staff_id = p_staff_id
      AND i.dispatcher_forced_next = true
      AND i.id IS DISTINCT FROM p_except_issue_id
      AND i.status IN ('open', 'in_progress', 'waiting_for_parts')
  );
$$;

REVOKE ALL ON FUNCTION public.technician_has_other_forced_issue(uuid, uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.technician_has_other_forced_issue(uuid, uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.enforce_dispatcher_forced_and_gps_audit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_org uuid;
  v_mgmt boolean;
  v_self boolean;
  v_taking boolean;
  v_starting boolean;
  v_forced_cols_changed boolean;
  v_auto_clear boolean;
BEGIN
  v_org := COALESCE(NEW.org_id, OLD.org_id);
  v_mgmt := v_org IS NOT NULL AND public.is_management_role(v_org);
  v_self := auth.uid() IS NOT NULL
    AND auth.uid() IS NOT DISTINCT FROM COALESCE(NEW.assigned_staff_id, OLD.assigned_staff_id);

  NEW.internal_comments := public.merge_immutable_issue_comments(
    OLD.internal_comments,
    NEW.internal_comments
  );

  IF OLD.gps_start_override IS TRUE THEN
    NEW.gps_start_override := true;
    NEW.gps_start_override_at := OLD.gps_start_override_at;
    NEW.gps_start_override_by := OLD.gps_start_override_by;
    NEW.gps_start_override_distance_m := OLD.gps_start_override_distance_m;
    NEW.gps_start_lat := OLD.gps_start_lat;
    NEW.gps_start_lng := OLD.gps_start_lng;
  ELSIF NEW.gps_start_override IS TRUE THEN
    NEW.gps_start_override_at := COALESCE(NEW.gps_start_override_at, now());
    NEW.gps_start_override_by := COALESCE(NEW.gps_start_override_by, auth.uid());
  ELSE
    NEW.gps_start_override_at := NULL;
    NEW.gps_start_override_by := NULL;
    NEW.gps_start_override_distance_m := NULL;
    NEW.gps_start_lat := NULL;
    NEW.gps_start_lng := NULL;
  END IF;

  IF NEW.status IN ('resolved', 'cancelled') THEN
    NEW.dispatcher_forced_next := false;
  END IF;

  IF NEW.assigned_staff_id IS DISTINCT FROM OLD.assigned_staff_id
     AND NOT (v_mgmt AND NEW.dispatcher_forced_next IS TRUE) THEN
    NEW.dispatcher_forced_next := false;
  END IF;

  IF NEW.dispatcher_forced_next IS NOT TRUE THEN
    NEW.dispatcher_forced_at := NULL;
    NEW.dispatcher_forced_by := NULL;
  ELSIF NEW.dispatcher_forced_next IS TRUE AND OLD.dispatcher_forced_next IS NOT TRUE THEN
    IF NEW.assigned_staff_id IS NULL THEN
      RAISE EXCEPTION 'ISSUE_FORCED_NEXT_NEEDS_ASSIGNEE';
    END IF;
    NEW.dispatcher_forced_at := COALESCE(NEW.dispatcher_forced_at, now());
    NEW.dispatcher_forced_by := COALESCE(NEW.dispatcher_forced_by, auth.uid());
  END IF;

  v_forced_cols_changed :=
    NEW.dispatcher_forced_next IS DISTINCT FROM OLD.dispatcher_forced_next
    OR NEW.dispatcher_forced_at IS DISTINCT FROM OLD.dispatcher_forced_at
    OR NEW.dispatcher_forced_by IS DISTINCT FROM OLD.dispatcher_forced_by;

  v_auto_clear :=
    OLD.dispatcher_forced_next IS TRUE
    AND NEW.dispatcher_forced_next IS NOT TRUE
    AND (
      NEW.status IN ('resolved', 'cancelled')
      OR NEW.assigned_staff_id IS DISTINCT FROM OLD.assigned_staff_id
    );

  IF v_forced_cols_changed AND NOT v_mgmt AND NOT v_auto_clear THEN
    RAISE EXCEPTION 'ISSUE_FORCED_NEXT_FORBIDDEN';
  END IF;

  v_taking :=
    v_self
    AND OLD.assigned_staff_id IS DISTINCT FROM NEW.assigned_staff_id
    AND NEW.assigned_staff_id = auth.uid();
  v_starting :=
    v_self
    AND NEW.status = 'in_progress'
    AND OLD.status IS DISTINCT FROM 'in_progress';

  IF (v_taking OR v_starting)
     AND public.technician_has_other_forced_issue(v_org, auth.uid(), NEW.id) THEN
    RAISE EXCEPTION 'ISSUE_FORCED_NEXT_REQUIRED';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_property_issue_lifecycle_forced_gps ON public.property_issues;
CREATE TRIGGER trg_enforce_property_issue_lifecycle_forced_gps
  BEFORE UPDATE ON public.property_issues
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_dispatcher_forced_and_gps_audit();

CREATE OR REPLACE FUNCTION public.log_property_issue_lifecycle()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_org uuid;
  v_actor uuid;
BEGIN
  v_actor := auth.uid();

  IF TG_OP = 'INSERT' THEN
    v_org := NEW.org_id;
    IF NEW.assigned_staff_id IS NOT NULL THEN
      INSERT INTO public.issue_lifecycle_events (org_id, issue_id, event_type, actor_user_id, payload)
      VALUES (
        v_org,
        NEW.id,
        'claimed',
        v_actor,
        jsonb_build_object('assigned_staff_id', NEW.assigned_staff_id)
      );
    END IF;
    RETURN NEW;
  END IF;

  v_org := COALESCE(NEW.org_id, OLD.org_id);

  IF OLD.assigned_staff_id IS NULL AND NEW.assigned_staff_id IS NOT NULL THEN
    INSERT INTO public.issue_lifecycle_events (org_id, issue_id, event_type, actor_user_id, payload)
    VALUES (
      v_org,
      NEW.id,
      'claimed',
      v_actor,
      jsonb_build_object('assigned_staff_id', NEW.assigned_staff_id)
    );
  END IF;

  IF (OLD.started_at IS NULL AND NEW.started_at IS NOT NULL)
     OR (OLD.status IS DISTINCT FROM 'in_progress' AND NEW.status = 'in_progress') THEN
    INSERT INTO public.issue_lifecycle_events (org_id, issue_id, event_type, actor_user_id, payload)
    VALUES (v_org, NEW.id, 'started', v_actor, '{}'::jsonb);
  END IF;

  IF NEW.status = 'cancelled' AND OLD.status IS DISTINCT FROM 'cancelled' THEN
    INSERT INTO public.issue_lifecycle_events (org_id, issue_id, event_type, actor_user_id, payload)
    VALUES (
      v_org,
      NEW.id,
      'cancelled',
      v_actor,
      jsonb_build_object('reason', NEW.cancel_reason)
    );
  END IF;

  IF NEW.cancel_requested_at IS NOT NULL AND OLD.cancel_requested_at IS NULL THEN
    INSERT INTO public.issue_lifecycle_events (org_id, issue_id, event_type, actor_user_id, payload)
    VALUES (
      v_org,
      NEW.id,
      'cancel_requested',
      v_actor,
      jsonb_build_object('reason', NEW.cancel_request_reason)
    );
  END IF;

  IF NEW.is_transfer_requested IS TRUE AND OLD.is_transfer_requested IS NOT TRUE THEN
    INSERT INTO public.issue_lifecycle_events (org_id, issue_id, event_type, actor_user_id, payload)
    VALUES (
      v_org,
      NEW.id,
      'transfer_requested',
      v_actor,
      jsonb_build_object(
        'transfer_to_vendor_id', NEW.transfer_to_vendor_id,
        'reason', NEW.transfer_reason
      )
    );
  END IF;

  IF NEW.transfer_authorized_at IS NOT NULL AND OLD.transfer_authorized_at IS NULL THEN
    INSERT INTO public.issue_lifecycle_events (org_id, issue_id, event_type, actor_user_id, payload)
    VALUES (
      v_org,
      NEW.id,
      'transfer_accepted',
      v_actor,
      jsonb_build_object('transfer_to_vendor_id', NEW.transfer_to_vendor_id)
    );
  END IF;

  IF NEW.is_transfer_requested IS NOT TRUE
     AND OLD.is_transfer_requested IS TRUE
     AND NEW.delegated_vendor_id IS NOT DISTINCT FROM OLD.delegated_vendor_id
     AND NEW.transfer_authorized_at IS NULL THEN
    INSERT INTO public.issue_lifecycle_events (org_id, issue_id, event_type, actor_user_id, payload)
    VALUES (v_org, NEW.id, 'transfer_rejected', v_actor, '{}'::jsonb);
  END IF;

  IF NEW.gps_start_override IS TRUE AND OLD.gps_start_override IS NOT TRUE THEN
    INSERT INTO public.issue_lifecycle_events (org_id, issue_id, event_type, actor_user_id, payload)
    VALUES (
      v_org,
      NEW.id,
      'gps_start_override',
      v_actor,
      jsonb_build_object(
        'distance_m', NEW.gps_start_override_distance_m,
        'lat', NEW.gps_start_lat,
        'lng', NEW.gps_start_lng
      )
    );
  END IF;

  IF NEW.dispatcher_forced_next IS TRUE AND OLD.dispatcher_forced_next IS NOT TRUE THEN
    INSERT INTO public.issue_lifecycle_events (org_id, issue_id, event_type, actor_user_id, payload)
    VALUES (
      v_org,
      NEW.id,
      'dispatcher_forced',
      v_actor,
      jsonb_build_object('assigned_staff_id', NEW.assigned_staff_id)
    );
  END IF;

  IF NEW.dispatcher_forced_next IS NOT TRUE AND OLD.dispatcher_forced_next IS TRUE THEN
    INSERT INTO public.issue_lifecycle_events (org_id, issue_id, event_type, actor_user_id, payload)
    VALUES (v_org, NEW.id, 'dispatcher_unforced', v_actor, '{}'::jsonb);
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_dispatcher_forced_next(p_issue_id uuid, p_forced boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
DECLARE
  v_org uuid;
  v_staff uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'ISSUE_AUTH_REQUIRED';
  END IF;

  SELECT org_id, assigned_staff_id
  INTO v_org, v_staff
  FROM public.property_issues
  WHERE id = p_issue_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ISSUE_NOT_FOUND';
  END IF;

  IF v_org IS NULL OR NOT public.is_management_role(v_org) THEN
    RAISE EXCEPTION 'ISSUE_FORCED_NEXT_FORBIDDEN';
  END IF;

  IF p_forced THEN
    IF v_staff IS NULL THEN
      RAISE EXCEPTION 'ISSUE_FORCED_NEXT_NEEDS_ASSIGNEE';
    END IF;

    UPDATE public.property_issues
    SET
      dispatcher_forced_next = false,
      dispatcher_forced_at = NULL,
      dispatcher_forced_by = NULL
    WHERE org_id = v_org
      AND assigned_staff_id = v_staff
      AND dispatcher_forced_next = true
      AND id IS DISTINCT FROM p_issue_id;

    UPDATE public.property_issues
    SET
      dispatcher_forced_next = true,
      dispatcher_forced_at = now(),
      dispatcher_forced_by = auth.uid()
    WHERE id = p_issue_id;
  ELSE
    UPDATE public.property_issues
    SET
      dispatcher_forced_next = false,
      dispatcher_forced_at = NULL,
      dispatcher_forced_by = NULL
    WHERE id = p_issue_id;
  END IF;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ISSUE_NOT_FOUND';
  END IF;
END;
$$;

COMMENT ON FUNCTION public.set_dispatcher_forced_next(uuid, boolean) IS
  'Dispatcher sets or clears the single next forced job for a technician.';

REVOKE ALL ON FUNCTION public.set_dispatcher_forced_next(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_dispatcher_forced_next(uuid, boolean) TO authenticated;

REVOKE ALL ON FUNCTION public.enforce_dispatcher_forced_and_gps_audit() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.enforce_dispatcher_forced_and_gps_audit() FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.technician_has_other_forced_issue(uuid, uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.technician_has_other_forced_issue(uuid, uuid, uuid) FROM anon, authenticated;
