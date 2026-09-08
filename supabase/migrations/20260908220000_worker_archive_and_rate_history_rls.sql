-- Cleaning managers may update staff cards (notes, emergency contact, archive flag).
DROP POLICY IF EXISTS cleaning_staff_write_management ON public.cleaning_staff;
CREATE POLICY cleaning_staff_write_management
  ON public.cleaning_staff
  FOR ALL
  TO authenticated
  USING (org_id IS NOT NULL AND public.is_management_role(org_id))
  WITH CHECK (org_id IS NOT NULL AND public.is_management_role(org_id));

-- Rate history SELECT currently checks profiles.fleet_role (fleet). Cleaning managers need access.
DROP POLICY IF EXISTS staff_rate_history_select_cleaning_mgmt ON public.staff_rate_history;
CREATE POLICY staff_rate_history_select_cleaning_mgmt
  ON public.staff_rate_history
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.memberships staff
      WHERE staff.user_id = staff_rate_history.staff_id
        AND public.is_management_role(staff.org_id)
    )
  );
