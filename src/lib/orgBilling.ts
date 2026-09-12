import { supabase } from './supabase'
import { isSubscriptionCurrent } from './moduleAccess'
import { parseFeatureList, type PricingPlanView } from './pricingDisplay'

export type BillingInterval = 'monthly' | 'yearly'

export type OrgSubscriptionView = {
  id: string
  org_id: string
  app_id: string
  status: string | null
  expires_at: string | null
  plan_id: string | null
  billing_interval: BillingInterval | null
  cancelled_at: string | null
}

const BILLING_ROLES = new Set(['owner', 'admin', 'coordinator'])

export function isBillingManagerRole(role: string | null | undefined): boolean {
  return BILLING_ROLES.has((role ?? '').trim().toLowerCase())
}

export function pickBillingMembership<T extends { org_id: string; role: string | null }>(
  memberships: T[],
): T | null {
  if (memberships.length === 0) return null
  return memberships.find((row) => isBillingManagerRole(row.role)) ?? memberships[0]
}

export function isOrgSubscriptionActive(sub: Pick<OrgSubscriptionView, 'status' | 'expires_at'> | null | undefined): boolean {
  if (!sub) return false
  return isSubscriptionCurrent(sub.status, sub.expires_at)
}

export function currentPlanForApp(
  plans: PricingPlanView[],
  sub: OrgSubscriptionView | null | undefined,
): PricingPlanView | null {
  if (!sub?.plan_id) return null
  return plans.find((plan) => plan.id === sub.plan_id) ?? null
}

export function upgradePlansFor(
  plans: PricingPlanView[],
  current: PricingPlanView | null,
): PricingPlanView[] {
  const sorted = [...plans].sort((a, b) => a.price_monthly - b.price_monthly)
  if (!current) return sorted
  return sorted.filter((plan) => plan.id !== current.id && plan.price_monthly > current.price_monthly)
}

export function mapPricingPlanRow(row: {
  id: string
  app_id: string
  name: string
  price_monthly: number | string
  price_yearly: number | string
  features: unknown
  max_users: number | null
  max_locations: number | null
  max_storage_gb: number | null
  ai_monthly_parse_limit: number | null
  has_ai_features: boolean | null
}): PricingPlanView {
  return {
    id: row.id,
    app_id: row.app_id,
    name: row.name,
    price_monthly: Number(row.price_monthly) || 0,
    price_yearly: Number(row.price_yearly) || 0,
    features: parseFeatureList(row.features),
    max_users: row.max_users,
    max_locations: row.max_locations,
    max_storage_gb: row.max_storage_gb,
    ai_monthly_parse_limit: row.ai_monthly_parse_limit,
    has_ai_features: row.has_ai_features,
  }
}

export async function activateOrgSubscriptionPlan(input: {
  orgId: string
  appId: string
  planId: string
  billingInterval: BillingInterval
}): Promise<OrgSubscriptionView> {
  const { data, error } = await supabase.rpc('activate_org_subscription_plan', {
    p_org_id: input.orgId,
    p_app_id: input.appId,
    p_plan_id: input.planId,
    p_billing_interval: input.billingInterval,
  })
  if (error) {
    console.error('[orgBilling] activate_org_subscription_plan:', error)
    throw new Error(error.message || 'Nie udało się aktywować planu.')
  }
  return data as OrgSubscriptionView
}

export async function cancelOrgSubscription(input: { orgId: string; appId: string }): Promise<OrgSubscriptionView> {
  const { data, error } = await supabase.rpc('cancel_org_subscription', {
    p_org_id: input.orgId,
    p_app_id: input.appId,
  })
  if (error) {
    console.error('[orgBilling] cancel_org_subscription:', error)
    throw new Error(error.message || 'Nie udało się zrezygnować z planu.')
  }
  return data as OrgSubscriptionView
}
