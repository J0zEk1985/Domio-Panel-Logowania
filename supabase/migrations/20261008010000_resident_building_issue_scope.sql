BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'resident_building_issue_scope'
  ) THEN
    CREATE TYPE public.resident_building_issue_scope AS ENUM (
      'resident_reports',
      'all_open'
    );
  END IF;
END $$;

ALTER TABLE public.resident_configs
  ADD COLUMN IF NOT EXISTS resident_building_issue_scope
    public.resident_building_issue_scope NOT NULL DEFAULT 'resident_reports';

COMMENT ON COLUMN public.resident_configs.resident_building_issue_scope IS
  'DOMIO Home building board. resident_reports: app and QR only (public_qr, tenant_qr). all_open: every open issue on the building, without reporter identity.';

-- Safe columns only. Residents must not read reporter name, phone, or id of other people.
CREATE OR REPLACE FUNCTION public.list_resident_building_issues(p_location_id uuid)
RETURNS TABLE (
  id uuid,
  description text,
  status public.issue_status_enum,
  created_at timestamptz,
  category text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_scope public.resident_building_issue_scope;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Wymagane logowanie';
  END IF;

  IF p_location_id IS NULL OR NOT public.has_active_location_access(p_location_id) THEN
    RAISE EXCEPTION 'Brak dostępu do budynku';
  END IF;

  SELECT rc.resident_building_issue_scope
  INTO v_scope
  FROM public.resident_configs rc
  WHERE rc.location_id = p_location_id;

  v_scope := COALESCE(v_scope, 'resident_reports'::public.resident_building_issue_scope);

  RETURN QUERY
  SELECT
    pi.id,
    pi.description,
    pi.status,
    pi.created_at,
    pi.category
  FROM public.property_issues pi
  WHERE pi.location_id = p_location_id
    AND pi.status IN (
      'new'::public.issue_status_enum,
      'open'::public.issue_status_enum,
      'in_progress'::public.issue_status_enum,
      'waiting_for_parts'::public.issue_status_enum,
      'delegated'::public.issue_status_enum
    )
    AND (
      v_scope = 'all_open'::public.resident_building_issue_scope
      OR pi.source IN (
        'public_qr'::public.issue_source_enum,
        'tenant_qr'::public.issue_source_enum
      )
    )
  ORDER BY pi.created_at DESC
  LIMIT 80;
END;
$$;

REVOKE ALL ON FUNCTION public.list_resident_building_issues(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_resident_building_issues(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.list_resident_building_issues(uuid) TO authenticated;

COMMENT ON FUNCTION public.list_resident_building_issues(uuid) IS
  'Open building issues for a resident of that location. Omits reporter identity. Scope comes from resident_configs.resident_building_issue_scope.';

-- Own reports stay visible in "Moje zgłoszenia", including pending approval.
DROP POLICY IF EXISTS "Residents view public issues" ON public.property_issues;
DROP POLICY IF EXISTS property_issues_select_own_reporter ON public.property_issues;

CREATE POLICY property_issues_select_own_reporter
  ON public.property_issues
  FOR SELECT
  TO authenticated
  USING (
    reporter_id = (SELECT auth.uid())
    AND public.has_active_location_access(location_id)
  );

NOTIFY pgrst, 'reload schema';

COMMIT;
