import { useState } from 'react'
import { applyPromoDiscount, previewPromoCode, type PromoPreview } from '../../lib/promoCodes'

type Props = {
  billingInterval: string
  disabled?: boolean
  promo: PromoPreview | null
  onChange: (promo: PromoPreview | null) => void
}

export function PromoCodeField({ billingInterval, disabled, promo, onChange }: Props) {
  const [promoInput, setPromoInput] = useState('')
  const [promoError, setPromoError] = useState<string | null>(null)
  const [promoBusy, setPromoBusy] = useState(false)

  const apply = async () => {
    setPromoError(null)
    setPromoBusy(true)
    try {
      const next = await previewPromoCode(promoInput, billingInterval)
      onChange(next)
    } catch (error) {
      onChange(null)
      const message = error instanceof Error ? error.message : 'Nie udało się sprawdzić kodu promocyjnego.'
      console.error('[PromoCodeField] preview:', error)
      setPromoError(message)
    } finally {
      setPromoBusy(false)
    }
  }

  return (
    <div className="space-y-2">
      <p className="text-sm font-medium text-muted-foreground">Kod promocyjny</p>
      <div className="flex gap-2">
        <input
          className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
          value={promoInput}
          disabled={disabled || promoBusy}
          placeholder="np. START20"
          onChange={(event) => {
            setPromoInput(event.target.value)
            if (promo) onChange(null)
          }}
        />
        <button
          type="button"
          disabled={disabled || promoBusy || !promoInput.trim()}
          onClick={() => void apply()}
          className="shrink-0 rounded-md border border-border px-3 text-sm font-medium hover:bg-muted/60 disabled:opacity-50"
        >
          {promoBusy ? 'Sprawdzanie…' : 'Zastosuj'}
        </button>
      </div>
      {promo ? (
        <p className="text-xs text-primary">
          Kod {promo.code}
          {promo.discountPercent != null ? ` · −${promo.discountPercent}%` : ''}
          {promo.discountAmount != null ? ` · −${promo.discountAmount} zł` : ''}
        </p>
      ) : null}
      {promoError ? <p className="text-xs text-destructive">{promoError}</p> : null}
    </div>
  )
}

export { applyPromoDiscount }
