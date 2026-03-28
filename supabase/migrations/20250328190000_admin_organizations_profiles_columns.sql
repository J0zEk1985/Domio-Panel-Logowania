-- Columns for admin panel: company address / NIP and split name on profiles
ALTER TABLE public.organizations
  ADD COLUMN IF NOT EXISTS nip text,
  ADD COLUMN IF NOT EXISTS address text,
  ADD COLUMN IF NOT EXISTS city text,
  ADD COLUMN IF NOT EXISTS postal_code text;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS first_name text,
  ADD COLUMN IF NOT EXISTS last_name text;

COMMENT ON COLUMN public.organizations.nip IS 'Tax ID (NIP), optional';
COMMENT ON COLUMN public.profiles.first_name IS 'Given name; optional if full_name is used';
