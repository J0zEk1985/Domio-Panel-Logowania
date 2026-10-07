BEGIN;

-- DOMIO Home is a paid, unit-priced module. The hub treated applications.is_free
-- as "Darmowy / Plan: bezpłatny" and listed the app without a subscription.

UPDATE public.applications
SET is_free = false
WHERE id = '3c0dfc11-2517-45b3-9981-4f338c4f54fc'
   OR lower(name) = 'domio home'
   OR domain_url ILIKE '%home.domio.com.pl%';

COMMIT;
