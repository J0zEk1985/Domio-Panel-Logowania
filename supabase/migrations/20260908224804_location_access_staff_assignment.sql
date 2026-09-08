-- Staff ↔ building access lives on location_access, not on phantom property_sections.

DELETE FROM public.location_access
WHERE location_id IS NULL
   OR user_id IS NULL;

ALTER TABLE public.location_access
  ALTER COLUMN location_id SET NOT NULL;

ALTER TABLE public.location_access
  ALTER COLUMN user_id SET NOT NULL;

COMMENT ON TABLE public.location_access IS
  'Staff (and optional resident) access to a cleaning location. Building assignment is independent of property_sections.';

COMMENT ON COLUMN public.location_access.access_type IS
  'permanent = default/legacy; staff = coordinator-assigned cleaner access to the whole building.';

CREATE UNIQUE INDEX IF NOT EXISTS location_access_staff_location_user_uidx
  ON public.location_access (location_id, user_id)
  WHERE unit_number IS NULL;

INSERT INTO public.location_access (location_id, user_id, access_type)
SELECT DISTINCT ps.location_id, ps.assigned_staff_id, 'staff'
FROM public.property_sections ps
WHERE ps.assigned_staff_id IS NOT NULL
  AND ps.location_id IS NOT NULL
ON CONFLICT (location_id, user_id) WHERE unit_number IS NULL DO NOTHING;

UPDATE public.cleaning_tasks
SET section_id = NULL
WHERE section_id IN (
  SELECT id FROM public.property_sections WHERE name = 'Strefa ogólna'
);

UPDATE public.property_checklists
SET section_id = NULL
WHERE section_id IN (
  SELECT id FROM public.property_sections WHERE name = 'Strefa ogólna'
);

DELETE FROM public.property_sections
WHERE name = 'Strefa ogólna';

ALTER TABLE public.location_access ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.location_access FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.location_access TO authenticated;

DROP POLICY IF EXISTS "Manager Manage Location Access" ON public.location_access;
DROP POLICY IF EXISTS "CORE_LocationAccess_Manage" ON public.location_access;
DROP POLICY IF EXISTS "CORE_LocationAccess_ViewOwn" ON public.location_access;
DROP POLICY IF EXISTS location_access_select_own ON public.location_access;
DROP POLICY IF EXISTS location_access_select_management ON public.location_access;
DROP POLICY IF EXISTS location_access_write_management ON public.location_access;

CREATE POLICY location_access_select_own
  ON public.location_access
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY location_access_select_management
  ON public.location_access
  FOR SELECT
  TO authenticated
  USING (public.can_manage_location(location_id));

CREATE POLICY location_access_write_management
  ON public.location_access
  FOR ALL
  TO authenticated
  USING (public.can_manage_location(location_id))
  WITH CHECK (public.can_manage_location(location_id));
