-- Admin: pricing plans per application + global promo codes
-- RLS: platform admins only (uses public.is_platform_admin())

CREATE TABLE IF NOT EXISTS public.pricing_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  app_id uuid NOT NULL REFERENCES public.applications (id) ON DELETE CASCADE,
  name text NOT NULL,
  price_monthly numeric(12, 2) NOT NULL DEFAULT 0,
  price_yearly numeric(12, 2) NOT NULL DEFAULT 0,
  features jsonb NOT NULL DEFAULT '[]'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pricing_plans_app_id ON public.pricing_plans (app_id);

CREATE TABLE IF NOT EXISTS public.promo_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL,
  discount_percent numeric(5, 2),
  discount_amount numeric(12, 2),
  max_uses integer,
  used_count integer NOT NULL DEFAULT 0,
  valid_until date,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT promo_codes_code_unique UNIQUE (code)
);

ALTER TABLE public.pricing_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Platform admin full access pricing_plans" ON public.pricing_plans;
CREATE POLICY "Platform admin full access pricing_plans"
  ON public.pricing_plans
  FOR ALL
  TO authenticated
  USING (public.is_platform_admin())
  WITH CHECK (public.is_platform_admin());

DROP POLICY IF EXISTS "Platform admin full access promo_codes" ON public.promo_codes;
CREATE POLICY "Platform admin full access promo_codes"
  ON public.promo_codes
  FOR ALL
  TO authenticated
  USING (public.is_platform_admin())
  WITH CHECK (public.is_platform_admin());
