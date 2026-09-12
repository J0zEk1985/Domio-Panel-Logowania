-- Copy last sign-in from auth.users into profiles.last_login_at (one column, cheap).
-- Keep it in sync on future logins. Platform admins may read cleaning task logs.

CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.sync_profile_last_login_from_auth()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' OR NEW.last_sign_in_at IS DISTINCT FROM OLD.last_sign_in_at THEN
    UPDATE public.profiles
    SET last_login_at = NEW.last_sign_in_at
    WHERE id = NEW.id
      AND last_login_at IS DISTINCT FROM NEW.last_sign_in_at;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.sync_profile_last_login_from_auth() FROM PUBLIC;

DROP TRIGGER IF EXISTS trg_sync_profile_last_login ON auth.users;
CREATE TRIGGER trg_sync_profile_last_login
  AFTER INSERT OR UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION private.sync_profile_last_login_from_auth();

UPDATE public.profiles AS p
SET last_login_at = u.last_sign_in_at
FROM auth.users AS u
WHERE u.id = p.id
  AND u.last_sign_in_at IS NOT NULL
  AND p.last_login_at IS DISTINCT FROM u.last_sign_in_at;

DROP POLICY IF EXISTS task_execution_logs_select_platform_admin ON public.task_execution_logs;
CREATE POLICY task_execution_logs_select_platform_admin
  ON public.task_execution_logs
  FOR SELECT
  TO authenticated
  USING (public.is_platform_admin());
