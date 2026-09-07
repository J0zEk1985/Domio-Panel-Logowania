-- Allow Serwis technician roles on memberships and let managers write them.

ALTER TABLE public.memberships
  DROP CONSTRAINT IF EXISTS memberships_role_check;

ALTER TABLE public.memberships
  ADD CONSTRAINT memberships_role_check
  CHECK (
    role = ANY (
      ARRAY[
        'owner'::text,
        'admin'::text,
        'administrator'::text,
        'manager'::text,
        'coordinator'::text,
        'koordynator'::text,
        'cleaner'::text,
        'technik'::text,
        'wlasciciel'::text
      ]
    )
  );

DROP POLICY IF EXISTS memberships_manage_update ON public.memberships;
CREATE POLICY memberships_manage_update
  ON public.memberships
  FOR UPDATE
  TO authenticated
  USING (public.is_management_role(org_id))
  WITH CHECK (public.is_management_role(org_id));

DROP POLICY IF EXISTS memberships_manage_insert ON public.memberships;
CREATE POLICY memberships_manage_insert
  ON public.memberships
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_management_role(org_id));
