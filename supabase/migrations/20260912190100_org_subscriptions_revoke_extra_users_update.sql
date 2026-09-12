-- Table-level UPDATE on org_subscriptions still covers extra_users.
-- Restrict authenticated to every column except extra_users; RPC (postgres) remains the write path.

REVOKE UPDATE ON TABLE public.org_subscriptions FROM anon, authenticated;
GRANT UPDATE (
  id,
  org_id,
  app_id,
  status,
  created_at,
  expires_at,
  plan_id,
  billing_interval,
  cancelled_at
) ON public.org_subscriptions TO authenticated;
