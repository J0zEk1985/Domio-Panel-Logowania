import { supabase } from './supabase'

export type PromoPreview = {
  code: string
  discountPercent: number | null
  discountAmount: number | null
}

type PromoRpcResult = {
  ok?: boolean
  error?: string
  code?: string
  discount_percent?: number | null
  discount_amount?: number | null
}

function promoErrorMessage(code: string | undefined): string {
  switch (code) {
    case 'EMPTY':
      return 'Wpisz kod promocyjny.'
    case 'EXPIRED':
      return 'Ten kod promocyjny wygasł.'
    case 'LIMIT':
      return 'Ten kod promocyjny został już wykorzystany.'
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
  return {
    code: (row.code ?? '').toString(),
    discountPercent: percent != null && Number.isFinite(percent) ? percent : null,
    discountAmount: amount != null && Number.isFinite(amount) ? amount : null,
  }
}

export async function previewPromoCode(code: string): Promise<PromoPreview> {
  const { data, error } = await supabase.rpc('preview_promo_code', { p_code: code })
  if (error) {
    console.error('[promoCodes] preview_promo_code:', error)
    throw new Error(error.message || 'Nie udało się sprawdzić kodu promocyjnego.')
  }
  return mapPromoResult(data, 'Nie udało się sprawdzić kodu promocyjnego.')
}

export async function redeemPromoCode(code: string): Promise<PromoPreview> {
  const { data, error } = await supabase.rpc('redeem_promo_code', { p_code: code })
  if (error) {
    console.error('[promoCodes] redeem_promo_code:', error)
    throw new Error(error.message || 'Nie udało się zastosować kodu promocyjnego.')
  }
  return mapPromoResult(data, 'Nie udało się zastosować kodu promocyjnego.')
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
