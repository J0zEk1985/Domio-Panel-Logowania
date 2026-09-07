-- Managers may update profiles of staff in their organization (phone, name after create-worker).

DROP POLICY IF EXISTS profiles_manage_org_update ON public.profiles;
CREATE POLICY profiles_manage_org_update
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.memberships staff
      WHERE staff.user_id = profiles.id
        AND public.is_management_role(staff.org_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.memberships staff
      WHERE staff.user_id = profiles.id
        AND public.is_management_role(staff.org_id)
    )
  );
