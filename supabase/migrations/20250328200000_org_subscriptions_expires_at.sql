-- Optional subscription end time for org module access
ALTER TABLE public.org_subscriptions
  ADD COLUMN IF NOT EXISTS expires_at timestamp with time zone;

COMMENT ON COLUMN public.org_subscriptions.expires_at IS 'When the org subscription to this app ends; NULL means no fixed end date';
