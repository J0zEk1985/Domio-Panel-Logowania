-- Administracja had no published plan, so checkout matched the first Domio-* catalog
-- app (Cleaning) via the shared brand prefix. Seed a real plan and drop test copy.

INSERT INTO public.pricing_plans (
  app_id,
  name,
  price_monthly,
  price_yearly,
  features,
  is_active,
  max_users,
  max_locations,
  ai_monthly_parse_limit,
  has_ai_features
)
SELECT
  a.id,
  'Basic',
  99,
  1000,
  jsonb_build_array(
    'Triage zgłoszeń',
    'Wspólnoty i budynki',
    'Umowy i przeglądy',
    'Komunikaty dla mieszkańców'
  ),
  true,
  3,
  2,
  20,
  false
FROM public.applications a
WHERE lower(a.name) = 'domio administracja'
  AND NOT EXISTS (
    SELECT 1
    FROM public.pricing_plans p
    WHERE p.app_id = a.id
      AND p.is_active = true
  );

UPDATE public.pricing_plans p
SET features = jsonb_build_array(
  'Harmonogramy i mapa obiektów',
  'Aplikacja terenowa z checklistą',
  'Zgłoszenia usterek ze zdjęciem'
)
FROM public.applications a
WHERE p.app_id = a.id
  AND lower(a.name) = 'domio cleaning'
  AND p.features = '["Testowe informacje", "o module", "cleaning"]'::jsonb;
