BEGIN;

-- Product catalog required for pricing plans / checkout. Hub (panel logowania) is not a billable app.

INSERT INTO public.applications (id, name, domain_url, api_url, is_free, is_active, created_at)
VALUES
  ('ea68af49-245a-4d50-8848-2ab74b37c340', 'Domio Administracja', 'https://adm.domio.com.pl', NULL, false, true, '2026-01-08 23:03:56.889305+00'),
  ('606969b9-86f9-437d-b14c-1db4bd38e5a2', 'Domio Cleaning', 'https://cleaning.domio.com.pl', NULL, false, true, '2026-01-14 21:37:31.333034+00'),
  ('43dc07eb-978d-4a78-9e0a-125a0dc6e48a', 'Domio Flota', 'https://flota.domio.com.pl', NULL, false, true, '2026-01-24 17:02:39.265083+00'),
  ('3c0dfc11-2517-45b3-9981-4f338c4f54fc', 'Domio Home', 'https://home.domio.com.pl', NULL, true, true, '2026-01-08 23:03:56.889305+00'),
  ('8a33af18-04d8-4398-85ff-3535ef77ce01', 'Domio Serwis', 'https://serwis.domio.com.pl', NULL, false, true, '2026-09-09 23:28:50.223131+00')
ON CONFLICT (id) DO UPDATE
SET
  name = EXCLUDED.name,
  domain_url = EXCLUDED.domain_url,
  is_free = EXCLUDED.is_free,
  is_active = true;

UPDATE public.applications
SET is_active = false
WHERE lower(name) LIKE '%panel logowania%'
   OR lower(name) LIKE '%auth hub%'
   OR lower(domain_url) IN (
     'https://domio.com.pl',
     'https://www.domio.com.pl',
     'https://udomio.com.pl',
     'https://www.udomio.com.pl',
     'https://test.udomio.com.pl',
     'https://test.domio.com.pl'
   );

COMMIT;
