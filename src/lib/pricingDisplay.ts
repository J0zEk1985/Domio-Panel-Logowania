export type PricingPlanView = {
  id: string
  app_id: string
  name: string
  price_monthly: number
  price_yearly: number
  features: string[]
  max_users: number | null
  max_locations: number | null
  max_storage_gb: number | null
  ai_monthly_parse_limit: number | null
  has_ai_features: boolean | null
  extra_user_price_monthly: number | null
  extra_user_price_yearly: number | null
}

export function parseFeatureList(raw: unknown): string[] {
  if (Array.isArray(raw)) {
    return raw.map((x) => String(x).trim()).filter(Boolean)
  }
  return []
}

export function planLimitLines(plan: Pick<
  PricingPlanView,
  | 'max_users'
  | 'max_locations'
  | 'max_storage_gb'
  | 'ai_monthly_parse_limit'
  | 'has_ai_features'
  | 'extra_user_price_monthly'
  | 'extra_user_price_yearly'
>): string[] {
  const lines: string[] = []
  if (plan.max_users != null) {
    lines.push(plan.max_users === 0 ? 'Bez użytkowników' : `Do ${plan.max_users} użytkowników`)
  } else {
    lines.push('Użytkownicy bez limitu')
  }
  lines.push(...extraUserPriceLines(plan))
  if (plan.max_locations != null) {
    lines.push(`Do ${plan.max_locations} lokalizacji`)
  }
  if (plan.max_storage_gb != null) {
    lines.push(`${plan.max_storage_gb} GB pamięci`)
  }
  if (plan.ai_monthly_parse_limit != null) {
    lines.push(
      plan.ai_monthly_parse_limit === 0
        ? 'Bez analiz AI e-maili'
        : `${plan.ai_monthly_parse_limit} analiz AI e-maili / mies.`,
    )
  }
  if (plan.has_ai_features === true) {
    lines.push('Automatyczna analiza e-maili (forward)')
  }
  return lines
}

export function formatMoneyPln(value: number | null | undefined): string {
  if (value == null || Number.isNaN(Number(value))) return '—'
  return `${Number(value).toLocaleString('pl-PL', { minimumFractionDigits: 0, maximumFractionDigits: 2 })} zł`
}

export function formatDatePl(iso: string | null | undefined): string {
  if (!iso) return 'bez terminu'
  try {
    return new Intl.DateTimeFormat('pl-PL', { dateStyle: 'medium' }).format(new Date(iso))
  } catch {
    return '—'
  }
}

export function planPriceLabel(plan: Pick<PricingPlanView, 'price_monthly' | 'price_yearly'>, yearly: boolean): string {
  const amount = yearly ? plan.price_yearly : plan.price_monthly
  return `${formatMoneyPln(amount)} / ${yearly ? 'rok' : 'mies.'}`
}

export function extraUserPriceLines(
  plan: Pick<PricingPlanView, 'max_users' | 'extra_user_price_monthly' | 'extra_user_price_yearly'>,
): string[] {
  if (plan.max_users == null) return []
  const lines: string[] = []
  if (plan.extra_user_price_monthly != null) {
    lines.push(`+1 użytkownik / ${formatMoneyPln(plan.extra_user_price_monthly)} mies.`)
  }
  if (plan.extra_user_price_yearly != null) {
    lines.push(`+1 użytkownik / ${formatMoneyPln(plan.extra_user_price_yearly)} rok`)
  }
  return lines
}
