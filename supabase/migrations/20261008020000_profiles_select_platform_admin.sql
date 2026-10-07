BEGIN;

-- Platform admin must list every account in Panel Logowania.
-- profiles_select_same_org only returns coworkers in the admin's own organizations.

DROP POLICY IF EXISTS profiles_select_platform_admin ON public.profiles;
CREATE POLICY profiles_select_platform_admin
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_platform_admin()));

DROP POLICY IF EXISTS memberships_select_platform_admin ON public.memberships;
CREATE POLICY memberships_select_platform_admin
  ON public.memberships
  FOR SELECT
  TO authenticated
  USING ((SELECT public.is_platform_admin()));

COMMIT;
