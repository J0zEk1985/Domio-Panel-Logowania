-- Buildings are enrolled per module. New rows must not appear in Cleaning by default.

UPDATE public.cleaning_locations
SET is_cleaning_active = false
WHERE is_cleaning_active IS NULL;

UPDATE public.cleaning_locations
SET is_maintenance_active = false
WHERE is_maintenance_active IS NULL;

UPDATE public.cleaning_locations
SET is_admin_active = false
WHERE is_admin_active IS NULL;

UPDATE public.cleaning_locations cl
SET is_cleaning_active = false
WHERE COALESCE(cl.is_cleaning_active, true) = true
  AND COALESCE(cl.is_maintenance_active, false) = true
  AND cl.client_id IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.property_sections ps
    WHERE ps.location_id = cl.id
  );

ALTER TABLE public.cleaning_locations
  ALTER COLUMN is_cleaning_active SET DEFAULT false;

ALTER TABLE public.cleaning_locations
  ALTER COLUMN is_cleaning_active SET NOT NULL;

ALTER TABLE public.cleaning_locations
  ALTER COLUMN is_maintenance_active SET NOT NULL;

ALTER TABLE public.cleaning_locations
  ALTER COLUMN is_admin_active SET NOT NULL;

COMMENT ON COLUMN public.cleaning_locations.is_cleaning_active IS
  'Enrolled in DOMIO Cleaning. False until the building is added in that module.';

COMMENT ON COLUMN public.cleaning_locations.is_maintenance_active IS
  'Enrolled in DOMIO Serwis. False until the building is added in that module.';

COMMENT ON COLUMN public.cleaning_locations.is_admin_active IS
  'Enrolled in DOMIO Administracja.';

DROP POLICY IF EXISTS property_sections_write_management ON public.property_sections;
CREATE POLICY property_sections_write_management
  ON public.property_sections
  FOR ALL
  TO authenticated
  USING (public.can_manage_location(location_id))
  WITH CHECK (public.can_manage_location(location_id));
