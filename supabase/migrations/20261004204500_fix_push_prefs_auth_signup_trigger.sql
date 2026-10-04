BEGIN;

-- GoTrue inserts into auth.users with search_path typically limited to `auth`.
-- The previous trigger function used an unqualified table name and was not
-- SECURITY DEFINER, so signup and admin.createUser failed with:
--   relation "push_notification_preferences" does not exist
--   Database error saving new user

CREATE OR REPLACE FUNCTION public.init_push_notification_preferences()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.push_notification_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

ALTER FUNCTION public.init_push_notification_preferences() OWNER TO postgres;

REVOKE ALL ON FUNCTION public.init_push_notification_preferences() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.init_push_notification_preferences() TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.init_push_notification_preferences() TO postgres;

COMMENT ON FUNCTION public.init_push_notification_preferences() IS
  'Creates default push notification preferences for a new auth user. Must run as SECURITY DEFINER so GoTrue signup can resolve public.push_notification_preferences.';

COMMIT;
