-- Hard limits and AI flag for subscription plans (admin + downstream apps)
ALTER TABLE public.pricing_plans
  ADD COLUMN IF NOT EXISTS max_users integer;

ALTER TABLE public.pricing_plans
  ADD COLUMN IF NOT EXISTS max_locations integer;

ALTER TABLE public.pricing_plans
  ADD COLUMN IF NOT EXISTS max_storage_gb integer;

ALTER TABLE public.pricing_plans
  ADD COLUMN IF NOT EXISTS has_ai_features boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.pricing_plans.max_users IS 'Hard cap on users; NULL means unlimited.';
COMMENT ON COLUMN public.pricing_plans.max_locations IS 'Hard cap on locations/objects; NULL means unlimited.';
COMMENT ON COLUMN public.pricing_plans.max_storage_gb IS 'Storage limit in GB; NULL means unlimited.';
COMMENT ON COLUMN public.pricing_plans.has_ai_features IS 'Whether AI features are included in this plan.';
