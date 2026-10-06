-- ============================================================================
-- DOMIO Monetization: Seed Data (Development/Testing)
-- ============================================================================
-- Sample pricing plans for home and developer_warranty modules
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. PRICING PLANS
-- ---------------------------------------------------------------------------

-- Plan 1: DOMIO Home (unit-based pricing)
INSERT INTO public.pricing_plans (
  id,
  module,
  display_name,
  description,
  is_global,
  is_unit_based,
  price_per_unit,
  min_price,
  features,
  is_active
) VALUES (
  'a0000000-0000-0000-0000-000000000001'::uuid,
  'home',
  'DOMIO Home - Plan Standardowy',
  'Dostęp do aplikacji DOMIO Home dla mieszkańców wspólnoty. Cena uzależniona od liczby lokali mieszkalnych.',
  false, -- per-community
  true,  -- unit-based
  2.50,  -- 2.50 PLN za lokal
  99.00, -- minimum 99 PLN
  '[
    "Dostęp dla wszystkich mieszkańców",
    "Tablica ogłoszeń i komunikaty",
    "Zgłaszanie usterek",
    "Rezerwacje przestrzeni wspólnych",
    "Kontakt z zarządem"
  ]'::jsonb,
  true
) ON CONFLICT (id) DO NOTHING;

-- Plan 2: DOMIO Home - Plan Premium (higher rates, more features)
INSERT INTO public.pricing_plans (
  id,
  module,
  display_name,
  description,
  is_global,
  is_unit_based,
  price_per_unit,
  min_price,
  features,
  is_active
) VALUES (
  'a0000000-0000-0000-0000-000000000002'::uuid,
  'home',
  'DOMIO Home - Plan Premium',
  'Rozszerzony dostęp z dodatkowymi funkcjami premium dla dużych wspólnot.',
  false,
  true,
  3.50,  -- 3.50 PLN za lokal
  149.00, -- minimum 149 PLN
  '[
    "Wszystkie funkcje Standardowego",
    "Ankiety i głosowania online",
    "Kalendarz wydarzeń",
    "Marketplace oferty sąsiedzkie",
    "Priorytetowe wsparcie techniczne"
  ]'::jsonb,
  true
) ON CONFLICT (id) DO NOTHING;

-- Plan 3: Developer Warranty (global, flat rate)
INSERT INTO public.pricing_plans (
  id,
  module,
  display_name,
  description,
  is_global,
  is_unit_based,
  price_monthly,
  price_yearly,
  features,
  is_active
) VALUES (
  'a0000000-0000-0000-0000-000000000003'::uuid,
  'developer_warranty',
  'Usterki Deweloperskie',
  'Globalny moduł do zarządzania usterkami deweloperskimi. Dostęp dla wszystkich wspólnot zarządzanych przez administrację.',
  true,  -- org-wide
  false, -- flat rate
  199.00, -- 199 PLN/miesiąc
  1990.00, -- 1990 PLN/rok (oszczędność ~17%)
  '[
    "Globalny dostęp dla całej administracji",
    "Obsługa wszystkich wspólnot",
    "Zgłoszenia z przypisaniem do dewelopera",
    "Terminy gwarancji i ich monitorowanie",
    "Raporty i statystyki",
    "Integracja z modułem Serwis"
  ]'::jsonb,
  true
) ON CONFLICT (id) DO NOTHING;

-- Plan 4: Fleet Module (przykład innego modułu)
INSERT INTO public.pricing_plans (
  id,
  module,
  display_name,
  description,
  is_global,
  is_unit_based,
  price_monthly,
  price_yearly,
  features,
  is_active
) VALUES (
  'a0000000-0000-0000-0000-000000000004'::uuid,
  'fleet',
  'Zarządzanie Flotą',
  'Moduł do zarządzania flotą pojazdów organizacji.',
  true,
  false,
  299.00,
  2990.00,
  '[
    "Rejestr pojazdów",
    "Harmonogramy przeglądów",
    "Koszty eksploatacji",
    "Rezerwacje pojazdów",
    "Raporty i analizy"
  ]'::jsonb,
  true
) ON CONFLICT (id) DO NOTHING;

COMMIT;

-- ---------------------------------------------------------------------------
-- USAGE EXAMPLES
-- ---------------------------------------------------------------------------

-- Example 1: Calculate price for home plan with 20 units (should return min_price 99)
-- SELECT calculate_unit_based_price('a0000000-0000-0000-0000-000000000001'::uuid, 20);
-- Expected: 99.00

-- Example 2: Calculate price for home plan with 100 units
-- SELECT calculate_unit_based_price('a0000000-0000-0000-0000-000000000001'::uuid, 100);
-- Expected: 250.00 (100 * 2.50)

-- Example 3: Check available plans
-- SELECT 
--   module, 
--   display_name, 
--   is_unit_based,
--   price_per_unit,
--   min_price,
--   price_monthly,
--   price_yearly
-- FROM pricing_plans
-- WHERE is_active = true
-- ORDER BY module, display_name;
