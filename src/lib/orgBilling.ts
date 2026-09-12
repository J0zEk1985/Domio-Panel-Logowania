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
  extra_users: number
}

const BILLING_ROLES = new Set(['owner', 'admin', 'coordinator'])
const BILLING_OWNER_ROLES = new Set(['owner', 'wlasciciel'])

export function isBillingManagerRole(role: string | null | undefined): boolean {
  return BILLING_ROLES.has((role ?? '').trim().toLowerCase())
}

export function isOrgBillingOwnerRole(role: string | null | undefined): boolean {
  return BILLING_OWNER_ROLES.has((role ?? '').trim().toLowerCase())
}

export function canPurchaseExtraUsers(input: {
  role: string | null | undefined
  isPlatformAdmin: boolean
}): boolean {
  return input.isPlatformAdmin || isOrgBillingOwnerRole(input.role)
}

export function effectiveUserLimit(maxUsers: number | null, extraUsers: number): number | null {
  if (maxUsers == null) return null
  return maxUsers + Math.max(0, extraUsers)
}

export function extraUserPriceForInterval(
  plan: Pick<PricingPlanView, 'extra_user_price_monthly' | 'extra_user_price_yearly'>,
  interval: BillingInterval,
): number | null {
  const raw = interval === 'yearly' ? plan.extra_user_price_yearly : plan.extra_user_price_monthly
  return raw == null || Number.isNaN(raw) ? null : raw
}

export function planAllowsExtraUsers(
  plan: Pick<PricingPlanView, 'max_users' | 'extra_user_price_monthly' | 'extra_user_price_yearly'>,
  interval: BillingInterval,
): boolean {
  if (plan.max_users == null) return false
  return extraUserPriceForInterval(plan, interval) != null
}

export function extraUsersPeriodCost(extraUsers: number, unitPrice: number | null): number {
  if (unitPrice == null || extraUsers <= 0) return 0
  return extraUsers * unitPrice
}

export function parseExtraUsersCount(
  raw: unknown,
): { ok: true; value: number } | { ok: false; message: string } {
  const n = typeof raw === 'number' ? raw : Number(String(raw).trim())
  if (!Number.isFinite(n) || !Number.isInteger(n) || n < 0) {
    return { ok: false, message: 'Liczba dodatkowych użytkowników musi być liczbą całkowitą ≥ 0.' }
  }
  return { ok: true, value: n }
}

function optionalMoney(raw: number | string | null | undefined): number | null {
  if (raw == null || raw === '') return null
  const n = Number(raw)
  return Number.isFinite(n) ? n : null
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

export function mapOrgSubscriptionRow(row: {
  id: string
  org_id: string
  app_id: string
  status: string | null
  expires_at: string | null
  plan_id: string | null
  billing_interval: string | null
  cancelled_at: string | null
  extra_users?: number | null
}): OrgSubscriptionView {
  const interval =
    row.billing_interval === 'yearly' || row.billing_interval === 'monthly' ? row.billing_interval : null
  const extra = Number(row.extra_users)
  return {
    id: row.id,
    org_id: row.org_id,
    app_id: row.app_id,
    status: row.status,
    expires_at: row.expires_at,
    plan_id: row.plan_id,
    billing_interval: interval,
    cancelled_at: row.cancelled_at,
    extra_users: Number.isInteger(extra) && extra >= 0 ? extra : 0,
  }
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
  extra_user_price_monthly?: number | string | null
  extra_user_price_yearly?: number | string | null
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
    extra_user_price_monthly: optionalMoney(row.extra_user_price_monthly),
    extra_user_price_yearly: optionalMoney(row.extra_user_price_yearly),
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
  return mapOrgSubscriptionRow(data as Parameters<typeof mapOrgSubscriptionRow>[0])
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
  return mapOrgSubscriptionRow(data as Parameters<typeof mapOrgSubscriptionRow>[0])
}

export async function setOrgSubscriptionExtraUsers(input: {
  orgId: string
  appId: string
  extraUsers: number
}): Promise<OrgSubscriptionView> {
  const parsed = parseExtraUsersCount(input.extraUsers)
  if (!parsed.ok) {
    throw new Error(parsed.message)
  }
  const { data, error } = await supabase.rpc('set_org_subscription_extra_users', {
    p_org_id: input.orgId,
    p_app_id: input.appId,
    p_extra_users: parsed.value,
  })
  if (error) {
    console.error('[orgBilling] set_org_subscription_extra_users:', error)
    throw new Error(error.message || 'Nie udało się zapisać dodatkowych użytkowników.')
  }
  return mapOrgSubscriptionRow(data as Parameters<typeof mapOrgSubscriptionRow>[0])
}
