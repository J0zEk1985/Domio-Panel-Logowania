-- Public read of active pricing plans (module detail pricing section)
DROP POLICY IF EXISTS "Public can read active pricing plans" ON public.pricing_plans;
CREATE POLICY "Public can read active pricing plans"
  ON public.pricing_plans
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true);
