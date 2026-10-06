-- Platform admin writes on module pricing plans, and org-admin updates
-- needed by purchase, cancel, renew, and upgrade edge functions.

BEGIN;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.module_pricing_plans TO authenticated;
GRANT UPDATE ON public.module_access_grants TO authenticated;

DROP POLICY IF EXISTS pricing_plans_select ON public.module_pricing_plans;
CREATE POLICY pricing_plans_select
  ON public.module_pricing_plans
  FOR SELECT
  TO authenticated
  USING (is_active = true OR public.is_platform_admin());

DROP POLICY IF EXISTS pricing_plans_write ON public.module_pricing_plans;
CREATE POLICY pricing_plans_write
  ON public.module_pricing_plans
  FOR ALL
  TO authenticated
  USING (public.is_platform_admin())
  WITH CHECK (public.is_platform_admin());

DROP POLICY IF EXISTS module_subscriptions_update ON public.module_subscriptions;
CREATE POLICY module_subscriptions_update
  ON public.module_subscriptions
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.org_id = purchaser_org_id
        AND m.user_id = auth.uid()
        AND m.role IN ('owner', 'wlasciciel', 'admin', 'administrator')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.org_id = purchaser_org_id
        AND m.user_id = auth.uid()
        AND m.role IN ('owner', 'wlasciciel', 'admin', 'administrator')
    )
  );

DROP POLICY IF EXISTS module_access_grants_update ON public.module_access_grants;
CREATE POLICY module_access_grants_update
  ON public.module_access_grants
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.org_id = org_id
        AND m.user_id = auth.uid()
        AND m.role IN ('owner', 'wlasciciel', 'admin', 'administrator')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.org_id = org_id
        AND m.user_id = auth.uid()
        AND m.role IN ('owner', 'wlasciciel', 'admin', 'administrator')
    )
  );

DROP POLICY IF EXISTS payment_intents_update ON public.subscription_payment_intents;
CREATE POLICY payment_intents_update
  ON public.subscription_payment_intents
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.org_id = purchaser_org_id
        AND m.user_id = auth.uid()
        AND m.role IN ('owner', 'wlasciciel', 'admin', 'administrator')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.org_id = purchaser_org_id
        AND m.user_id = auth.uid()
        AND m.role IN ('owner', 'wlasciciel', 'admin', 'administrator')
    )
  );

COMMIT;
