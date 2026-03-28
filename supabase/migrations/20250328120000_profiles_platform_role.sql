-- Platform admin role + profile timestamps for admin panel
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS platform_role text NOT NULL DEFAULT 'user';

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS created_at timestamp with time zone NOT NULL DEFAULT now();

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS last_login_at timestamp with time zone;

COMMENT ON COLUMN public.profiles.platform_role IS 'Platform panel: user | admin';

CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND lower(trim(p.platform_role)) = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_platform_admin() TO authenticated;
