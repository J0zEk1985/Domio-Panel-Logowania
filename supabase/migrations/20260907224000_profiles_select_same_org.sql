-- Org coworkers must be readable for team lists (useOrgStaff joins profiles).
-- Previously only profiles_select_own existed, so dispatchers saw only themselves.

DROP POLICY IF EXISTS profiles_select_same_org ON public.profiles;

CREATE POLICY profiles_select_same_org
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    (auth.uid() = id)
    OR EXISTS (
      SELECT 1
      FROM public.memberships AS target_m
      INNER JOIN public.memberships AS my_m
        ON my_m.org_id = target_m.org_id
       AND my_m.user_id = auth.uid()
      WHERE target_m.user_id = profiles.id
    )
  );
