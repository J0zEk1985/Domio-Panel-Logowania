-- Cleaning owner/coordinator can mark a handed-off ticket resolved
-- before Administracja forwards it to Serwis / marketplace / B2B.

CREATE OR REPLACE FUNCTION public.resolve_cleaning_released_property_issue(p_issue_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_issue public.property_issues%ROWTYPE;
  v_updated integer;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'ISSUE_AUTH_REQUIRED';
  END IF;

  SELECT * INTO v_issue
  FROM public.property_issues
  WHERE id = p_issue_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ISSUE_NOT_FOUND';
  END IF;

  IF NOT public.is_management_role(v_issue.org_id) THEN
    RAISE EXCEPTION 'ISSUE_CLEANING_RESOLVE_FORBIDDEN';
  END IF;

  IF lower(btrim(COALESCE(v_issue.source::text, ''))) NOT IN ('cleaning', 'cleaning_app') THEN
    RAISE EXCEPTION 'ISSUE_CLEANING_RESOLVE_FORBIDDEN';
  END IF;

  IF v_issue.released_from_cleaning_at IS NULL THEN
    RAISE EXCEPTION 'ISSUE_CLEANING_RESOLVE_FORBIDDEN';
  END IF;

  IF v_issue.status IS DISTINCT FROM 'pending_admin_approval'::public.issue_status_enum
     AND v_issue.status IS DISTINCT FROM 'open'::public.issue_status_enum
     AND v_issue.status IS DISTINCT FROM 'new'::public.issue_status_enum THEN
    RAISE EXCEPTION 'ISSUE_CLEANING_RESOLVE_FORBIDDEN';
  END IF;

  IF v_issue.assigned_staff_id IS NOT NULL
     OR v_issue.delegated_vendor_id IS NOT NULL
     OR v_issue.claimed_by_org_id IS NOT NULL
     OR v_issue.is_public_broadcast IS TRUE THEN
    RAISE EXCEPTION 'ISSUE_CLEANING_RESOLVE_FORBIDDEN';
  END IF;

  UPDATE public.property_issues
  SET
    status = 'resolved',
    resolved_at = COALESCE(resolved_at, now())
  WHERE id = p_issue_id
    AND released_from_cleaning_at IS NOT NULL
    AND assigned_staff_id IS NULL
    AND delegated_vendor_id IS NULL
    AND claimed_by_org_id IS NULL
    AND COALESCE(is_public_broadcast, false) IS NOT TRUE
    AND status IN (
      'pending_admin_approval'::public.issue_status_enum,
      'open'::public.issue_status_enum,
      'new'::public.issue_status_enum
    );

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated = 0 THEN
    RAISE EXCEPTION 'ISSUE_CLEANING_RESOLVE_FORBIDDEN';
  END IF;
END;
$$;

COMMENT ON FUNCTION public.resolve_cleaning_released_property_issue(uuid) IS
  'Allows Cleaning owner/coordinator to resolve a ticket after handoff, until Administracja forwards it further.';

REVOKE ALL ON FUNCTION public.resolve_cleaning_released_property_issue(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_cleaning_released_property_issue(uuid) TO authenticated;
