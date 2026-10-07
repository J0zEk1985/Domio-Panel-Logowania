import type { AppModule, SubscriptionStatus } from '../types/monetization'

/** Statuses that still occupy a global (org-wide) license. */
const OPEN_GLOBAL_STATUSES = new Set<SubscriptionStatus>([
  'active',
  'blocked_pending_payment',
  'suspended',
])

type GlobalSubscriptionProbe = {
  module: AppModule
  purchaser_org_id: string
  beneficiary_community_id: string | null
  status: SubscriptionStatus
}

/**
 * True when the org already holds an open org-wide subscription for the module.
 * A new purchase would duplicate access that already covers every community.
 */
export function isOpenGlobalModuleSubscription(
  subscription: GlobalSubscriptionProbe,
  module: AppModule,
  purchaserOrgId: string | null,
): boolean {
  if (!purchaserOrgId) return false
  return (
    subscription.purchaser_org_id === purchaserOrgId &&
    subscription.module === module &&
    subscription.beneficiary_community_id == null &&
    OPEN_GLOBAL_STATUSES.has(subscription.status)
  )
}
