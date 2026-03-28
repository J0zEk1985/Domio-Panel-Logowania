-- Audit: accepted privacy & marketing document versions at signup
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS privacy_version text;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS marketing_version text;
