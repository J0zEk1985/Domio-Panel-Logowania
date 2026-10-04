BEGIN;

-- Canonical Administracja host is adm.domio.com.pl (admin.domio.com.pl has invalid cert).
UPDATE public.applications
SET domain_url = 'https://adm.domio.com.pl'
WHERE domain_url ILIKE '%admin.domio.com.pl%'
   OR (
     lower(name) = 'domio administracja'
     AND domain_url IS DISTINCT FROM 'https://adm.domio.com.pl'
   );

COMMIT;
