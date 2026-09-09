-- Bind org subscriptions to a pricing plan, let platform admins manage them,
-- hide expired access, and enforce max_users from the assigned plan.

ALTER TABLE public.org_subscriptions
  ADD COLUMN IF NOT EXISTS plan_id uuid REFERENCES public.pricing_plans(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_org_subscriptions_plan_id
  ON public.org_subscriptions (plan_id);

DROP POLICY IF EXISTS "Platform admin full access org_subscriptions" ON public.org_subscriptions;
CREATE POLICY "Platform admin full access org_subscriptions"
  ON public.org_subscriptions
  TO authenticated
  USING (public.is_platform_admin())
  WITH CHECK (public.is_platform_admin());

CREATE OR REPLACE VIEW public.user_app_access
  WITH (security_invoker = true) AS
SELECT DISTINCT
  m.user_id,
  os.app_id,
  a.name AS app_name,
  a.domain_url AS app_domain_url,
  a.api_url AS app_api_url,
  m.org_id,
  o.name AS org_name,
  os.status AS subscription_status
FROM public.memberships m
JOIN public.org_subscriptions os ON os.org_id = m.org_id
JOIN public.applications a ON a.id = os.app_id
JOIN public.organizations o ON o.id = m.org_id
WHERE os.status = 'active'
  AND COALESCE(a.is_active, true) = true
  AND (os.expires_at IS NULL OR os.expires_at > now());

CREATE OR REPLACE FUNCTION public.enforce_membership_user_limit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_count integer;
  plan_limit integer;
BEGIN
  IF public.is_platform_admin() THEN
    RETURN NEW;
  END IF;

  SELECT MIN(pp.max_users)
    INTO plan_limit
  FROM public.org_subscriptions os
  JOIN public.pricing_plans pp ON pp.id = os.plan_id
  WHERE os.org_id = NEW.org_id
    AND os.status = 'active'
    AND (os.expires_at IS NULL OR os.expires_at > now())
    AND pp.max_users IS NOT NULL;

  IF plan_limit IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COUNT(*)::integer
    INTO current_count
  FROM public.memberships
  WHERE org_id = NEW.org_id;

  IF TG_OP = 'INSERT' AND current_count >= plan_limit THEN
    RAISE EXCEPTION 'Limit użytkowników planu (%) został osiągnięty dla tej organizacji', plan_limit
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_membership_user_limit ON public.memberships;
CREATE TRIGGER trg_enforce_membership_user_limit
  BEFORE INSERT ON public.memberships
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_membership_user_limit();
