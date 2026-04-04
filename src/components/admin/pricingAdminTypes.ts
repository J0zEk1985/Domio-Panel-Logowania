export type PricingPlanRow = {
  id: string
  app_id: string
  name: string
  price_monthly: number
  price_yearly: number
  features: unknown
  is_active: boolean
  max_users?: number | null
  max_locations?: number | null
  max_storage_gb?: number | null
  has_ai_features?: boolean
  created_at?: string
  updated_at?: string
  /** Supabase may return a single object or one-element array for the FK embed. */
  applications: { name: string } | { name: string }[] | null
}

export function applicationName(row: PricingPlanRow): string {
  const a = row.applications
  if (a == null) return '—'
  if (Array.isArray(a)) return a[0]?.name ?? '—'
  return a.name ?? '—'
}

export type PromoCodeRow = {
  id: string
  code: string
  discount_percent: number | null
  discount_amount: number | null
  max_uses: number | null
  used_count: number
  valid_until: string | null
  is_active: boolean
}

export function emptyPlanForm() {
  return {
    appId: '',
    name: '',
    priceMonthly: '',
    priceYearly: '',
    featuresString: '',
    maxUsers: '',
    maxLocations: '',
    maxStorageGb: '',
    hasAiFeatures: false,
  }
}

export function emptyPromoForm() {
  return {
    code: '',
    discountPercent: '',
    discountAmount: '',
    maxUses: '',
    validUntil: '',
  }
}
