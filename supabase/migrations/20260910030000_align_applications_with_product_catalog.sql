-- Align hub applications with live DOMIO product modules (landing catalog).
-- Keep existing row IDs so subscriptions and pricing plans stay attached.

-- Hub is the login panel itself, not a product module.
UPDATE public.applications
SET
  name = 'Panel logowania DOMIO',
  is_active = false
WHERE lower(name) IN ('auth hub', 'panel logowania domio')
   OR domain_url IN (
     'https://domio.com.pl',
     'https://www.domio.com.pl',
     'https://udomio.com.pl',
     'https://www.udomio.com.pl'
   );

UPDATE public.applications
SET
  name = 'Domio Cleaning',
  domain_url = 'https://cleaning.domio.com.pl',
  is_free = false,
  is_active = true
WHERE lower(name) IN ('cleaning module', 'domio cleaning')
   OR domain_url ILIKE '%cleaning.domio.com.pl%';

UPDATE public.applications
SET
  name = 'Domio Flota',
  domain_url = 'https://flota.domio.com.pl',
  is_free = false,
  is_active = true
WHERE lower(name) IN ('obsługa floty', 'domio flota')
   OR domain_url ILIKE '%flota.domio.com.pl%';

-- Reuse the unused premium placeholder as Administracja.
UPDATE public.applications
SET
  name = 'Domio Administracja',
  domain_url = 'https://admin.domio.com.pl',
  is_free = false,
  is_active = true
WHERE lower(name) IN ('panel zarządzania', 'domio administracja')
   OR domain_url IN (
     'https://premium-app.pl',
     'https://admin.domio.com.pl',
     'https://adm.domio.com.pl'
   );

-- Reuse the unused free placeholder as Home (resident app).
UPDATE public.applications
SET
  name = 'Domio Home',
  domain_url = 'https://home.domio.com.pl',
  is_free = true,
  is_active = true
WHERE lower(name) IN ('portal ogólny', 'domio home')
   OR domain_url IN (
     'https://free-app.pl',
     'https://home.domio.com.pl'
   );

INSERT INTO public.applications (name, domain_url, is_free, is_active)
SELECT 'Domio Serwis', 'https://serwis.domio.com.pl', false, true
WHERE NOT EXISTS (
  SELECT 1
  FROM public.applications
  WHERE domain_url ILIKE '%serwis.domio.com.pl%'
     OR lower(name) = 'domio serwis'
);
