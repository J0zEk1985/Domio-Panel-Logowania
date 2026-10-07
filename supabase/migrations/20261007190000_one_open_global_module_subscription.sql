BEGIN;

-- One open org-wide license per organization and module.
-- Expired and cancelled rows stay, so the same service can be bought again later.
CREATE UNIQUE INDEX IF NOT EXISTS module_subscriptions_one_open_global
  ON public.module_subscriptions (purchaser_org_id, module)
  WHERE beneficiary_community_id IS NULL
    AND status IN ('active', 'blocked_pending_payment', 'suspended');

COMMENT ON INDEX public.module_subscriptions_one_open_global IS
  'Blocks a second open global subscription for the same org and module.';

COMMIT;
