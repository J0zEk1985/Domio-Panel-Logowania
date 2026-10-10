import { supabase } from './supabase'

export type PromoPreview = {
  code: string
  discountPercent: number | null
  discountAmount: number | null
  allowedBillingIntervals: string[] | null
}

type PromoRpcResult = {
  ok?: boolean
  error?: string
  code?: string
  discount_percent?: number | null
  discount_amount?: number | null
  allowed_billing_intervals?: string[] | null
}

function promoErrorMessage(code: string | undefined): string {
  switch (code) {
    case 'EMPTY':
      return 'Wpisz kod promocyjny.'
    case 'EXPIRED':
      return 'Ten kod promocyjny wygasł.'
    case 'LIMIT':
      return 'Ten kod promocyjny został już wykorzystany.'
    case 'INTERVAL_NOT_ALLOWED':
      return 'Ten kod promocyjny nie może być użyty dla wybranego okresu rozliczenia.'
    default:
      return 'Nieprawidłowy kod promocyjny.'
  }
}

function mapPromoResult(raw: unknown, fallback: string): PromoPreview {
  const row = (raw ?? {}) as PromoRpcResult
  if (!row.ok) {
    throw new Error(promoErrorMessage(row.error) || fallback)
  }
  const percent = row.discount_percent == null ? null : Number(row.discount_percent)
  const amount = row.discount_amount == null ? null : Number(row.discount_amount)
  const intervals = Array.isArray(row.allowed_billing_intervals) ? row.allowed_billing_intervals : null
  return {
    code: (row.code ?? '').toString(),
    discountPercent: percent != null && Number.isFinite(percent) ? percent : null,
    discountAmount: amount != null && Number.isFinite(amount) ? amount : null,
    allowedBillingIntervals: intervals,
  }
}

export async function previewPromoCode(code: string, billingInterval?: string): Promise<PromoPreview> {
  const { data, error } = await supabase.rpc('preview_promo_code', { 
    p_code: code,
    p_billing_interval: billingInterval || null,
  })
  if (error) {
    console.error('[promoCodes] preview_promo_code:', error)
    throw new Error(error.message || 'Nie udało się sprawdzić kodu promocyjnego.')
  }
  return mapPromoResult(data, 'Nie udało się sprawdzić kodu promocyjnego.')
}

export async function redeemPromoCode(code: string, billingInterval?: string): Promise<PromoPreview> {
  const { data, error } = await supabase.rpc('redeem_promo_code', { 
    p_code: code,
    p_billing_interval: billingInterval || null,
  })
  if (error) {
    console.error('[promoCodes] redeem_promo_code:', error)
    throw new Error(error.message || 'Nie udało się zastosować kodu promocyjnego.')
  }
  return mapPromoResult(data, 'Nie udało się zastosować kodu promocyjnego.')
}

export const PAYMENT_NOT_LIVE_MESSAGE =
  'Płatność online nie jest jeszcze dostępna. Plan można aktywować tylko kodem rabatowym 100%.'

export function isFullPercentPromo(promo: PromoPreview | null): boolean {
  return promo != null && promo.discountPercent != null && promo.discountPercent >= 100
}

export function applyPromoDiscount(basePrice: number, promo: PromoPreview | null): number {
  let next = Number(basePrice) || 0
  if (promo?.discountPercent != null) {
    next *= 1 - promo.discountPercent / 100
  }
  if (promo?.discountAmount != null) {
    next -= promo.discountAmount
  }
  return Math.max(0, Math.round(next * 100) / 100)
}
