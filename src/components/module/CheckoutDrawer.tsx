import { useEffect, useMemo, useState } from 'react'
import { CheckCircle2, CreditCard, Lock, Smartphone, Building2, X } from 'lucide-react'
import { toast } from 'sonner'
import {
  activateOrgSubscriptionPlan,
  ensureMyBillingOrganization,
  type BillingInterval,
} from '../../lib/orgBilling'
import {
  applyPromoDiscount,
  previewPromoCode,
  redeemPromoCode,
  type PromoPreview,
} from '../../lib/promoCodes'
import { formatMoneyPln } from '../../lib/pricingDisplay'
import type { PricingPlan } from './PricingSection'
import { OrgNipLookupField } from '../dashboard/OrgNipLookupField'
import type { BillingGusPreview } from '../../lib/billingNipLookup'
import { upsertBillingOrgLegalEntity } from '../../lib/billingOrgLegalEntity'

type PaymentMethod = 'card' | 'blik' | 'payu'

type Props = {
  open: boolean
  onClose: () => void
  moduleName: string
  plan: PricingPlan
  yearly: boolean
  onPurchased: () => void
}

const fieldClass =
  'w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-60'

const PAYMENT_METHODS: { value: PaymentMethod; label: string; icon: typeof CreditCard }[] = [
  { value: 'card', label: 'Karta kredytowa', icon: CreditCard },
  { value: 'blik', label: 'BLIK', icon: Smartphone },
  { value: 'payu', label: 'PayU / Przelewy24', icon: Building2 },
]

export function CheckoutDrawer({ open, onClose, moduleName, plan, yearly, onPurchased }: Props) {
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>('card')
  const [fullName, setFullName] = useState('')
  const [companyName, setCompanyName] = useState('')
  const [nip, setNip] = useState('')
  const [gusPreview, setGusPreview] = useState<BillingGusPreview | null>(null)
  const [promoInput, setPromoInput] = useState('')
  const [promo, setPromo] = useState<PromoPreview | null>(null)
  const [promoError, setPromoError] = useState<string | null>(null)
  const [promoBusy, setPromoBusy] = useState(false)
  const [busy, setBusy] = useState(false)
  const [success, setSuccess] = useState(false)

  useEffect(() => {
    if (!open) return
    setPaymentMethod('card')
    setFullName('')
    setCompanyName('')
    setNip('')
    setGusPreview(null)
    setPromoInput('')
    setPromo(null)
    setPromoError(null)
    setBusy(false)
    setSuccess(false)
  }, [open, plan.id, yearly])

  const basePrice = yearly ? plan.yearlyPrice : plan.monthlyPrice
  const payable = useMemo(() => applyPromoDiscount(basePrice, promo), [basePrice, promo])
  const interval: BillingInterval = yearly ? 'yearly' : 'monthly'
  const cycleLabel = yearly ? 'Rocznie' : 'Miesięcznie'

  const applyCode = async () => {
    setPromoError(null)
    setPromoBusy(true)
    try {
      const next = await previewPromoCode(promoInput)
      setPromo(next)
      toast.success(`Zastosowano kod ${next.code}.`)
    } catch (err) {
      setPromo(null)
      setPromoError(err instanceof Error ? err.message : 'Nie udało się sprawdzić kodu.')
    } finally {
      setPromoBusy(false)
    }
  }

  const confirmPay = async () => {
    const orgName = companyName.trim() || fullName.trim()
    if (!orgName) {
      toast.error('Podaj imię i nazwisko albo nazwę firmy.')
      return
    }
    const nipDigits = nip.replace(/\s+/g, '')
    if (nipDigits && !/^\d{10}$/.test(nipDigits)) {
      toast.error('NIP musi składać się z 10 cyfr.')
      return
    }

    setBusy(true)
    try {
      const orgId = await ensureMyBillingOrganization({
        name: orgName,
        nip: nipDigits || null,
      })
      if (nipDigits) {
        try {
          await upsertBillingOrgLegalEntity({
            orgId,
            nip: nipDigits,
            legalName: orgName,
            city: '',
            postalCode: '',
            address: '',
            phone: '',
            gus: gusPreview,
            listedInProviderDirectory: false,
          })
        } catch (leErr) {
          console.error('[CheckoutDrawer] legal entity:', leErr)
        }
      }
      await activateOrgSubscriptionPlan({
        orgId,
        appId: plan.appId,
        planId: plan.id,
        billingInterval: interval,
      })
      if (promo?.code) {
        try {
          await redeemPromoCode(promo.code)
        } catch (promoErr) {
          console.error('[CheckoutDrawer] redeem after activate:', promoErr)
        }
      }
      setSuccess(true)
    } catch (err) {
      console.error('[CheckoutDrawer] confirm:', err)
      toast.error(err instanceof Error ? err.message : 'Nie udało się dokończyć zamówienia.')
    } finally {
      setBusy(false)
    }
  }

  if (!open) return null

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
      role="dialog"
      aria-modal="true"
      aria-labelledby="checkout-title"
      onClick={onClose}
    >
      <div
        className="bg-card text-card-foreground rounded-2xl max-w-lg w-full max-h-[90vh] flex flex-col shadow-lg border border-border overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between gap-4 p-4 border-b border-border/60">
          <div>
            <h3 id="checkout-title" className="font-display font-semibold text-lg">
              Zamówienie
            </h3>
            <p className="text-xs text-muted-foreground mt-1">Dokończ zakup modułu</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-md p-2 text-muted-foreground hover:bg-muted hover:text-foreground"
            aria-label="Zamknij"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="overflow-y-auto p-6 space-y-6 flex-1">
          {success ? (
            <div className="flex flex-col items-center justify-center py-8 text-center">
              <div className="p-4 rounded-full bg-primary/10 mb-6">
                <CheckCircle2 className="h-12 w-12 text-primary" />
              </div>
              <h4 className="font-display text-2xl font-bold mb-2">Plan aktywowany</h4>
              <p className="text-muted-foreground mb-6">
                {moduleName} — {plan.name} jest już dostępny w panelu.
              </p>
              <button
                type="button"
                onClick={onPurchased}
                className="rounded-md px-6 py-3 text-sm font-medium gradient-brand text-primary-foreground"
              >
                Przejdź do panelu
              </button>
            </div>
          ) : (
            <>
              <div className="rounded-xl bg-muted/50 border border-border/50 p-4 space-y-2">
                <h4 className="font-display font-semibold text-sm text-muted-foreground uppercase tracking-wider">
                  Podsumowanie zamówienia
                </h4>
                <div className="flex justify-between items-start gap-3">
                  <div>
                    <p className="font-semibold">{moduleName}</p>
                    <p className="text-sm text-muted-foreground">
                      Plan {plan.name} · {cycleLabel}
                    </p>
                    {promo ? (
                      <p className="text-xs text-primary mt-1">
                        Kod {promo.code}
                        {promo.discountPercent != null ? ` · −${promo.discountPercent}%` : ''}
                        {promo.discountAmount != null ? ` · −${formatMoneyPln(promo.discountAmount)}` : ''}
                      </p>
                    ) : null}
                  </div>
                  <div className="text-right">
                    {promo && payable !== basePrice ? (
                      <p className="text-sm text-muted-foreground line-through">{formatMoneyPln(basePrice)}</p>
                    ) : null}
                    <p className="font-display text-xl font-bold">{formatMoneyPln(payable)}</p>
                  </div>
                </div>
              </div>

              <fieldset className="space-y-3">
                <legend className="text-sm font-semibold">Metoda płatności</legend>
                <div className="grid gap-2">
                  {PAYMENT_METHODS.map((method) => {
                    const Icon = method.icon
                    const checked = paymentMethod === method.value
                    return (
                      <label
                        key={method.value}
                        className={`flex items-center gap-3 rounded-xl border px-4 py-3 cursor-pointer transition-colors ${
                          checked ? 'border-primary bg-primary/5' : 'border-border/50 bg-muted/30 hover:bg-muted/50'
                        }`}
                      >
                        <input
                          type="radio"
                          name="checkout-payment"
                          className="accent-primary"
                          checked={checked}
                          disabled={busy}
                          onChange={() => setPaymentMethod(method.value)}
                        />
                        <Icon className="h-4 w-4 text-muted-foreground" />
                        <span className="text-sm font-medium">{method.label}</span>
                      </label>
                    )
                  })}
                </div>
                <p className="text-xs text-muted-foreground">
                  Bramka płatności online zostanie podłączona w kolejnym kroku. Teraz plan przypisujemy do Twojej firmy.
                </p>
              </fieldset>

              <div className="space-y-3">
                <p className="text-sm font-semibold">Dane do faktury</p>
                <input
                  className={fieldClass}
                  placeholder="Imię i nazwisko"
                  value={fullName}
                  disabled={busy}
                  autoComplete="name"
                  onChange={(e) => setFullName(e.target.value)}
                />
                <input
                  className={fieldClass}
                  placeholder="Firma (opcjonalnie)"
                  value={companyName}
                  disabled={busy}
                  autoComplete="organization"
                  onChange={(e) => setCompanyName(e.target.value)}
                />
                <OrgNipLookupField
                  idPrefix="checkout"
                  nip={nip}
                  disabled={busy}
                  onNipChange={(value) => {
                    setNip(value)
                    setGusPreview(null)
                  }}
                  onFilled={(filled) => {
                    setNip(filled.nip)
                    setCompanyName(filled.name)
                    setGusPreview(filled.gusPreview)
                  }}
                />
              </div>

              <div className="space-y-2">
                <p className="text-sm font-semibold">Kod promocyjny</p>
                <div className="flex gap-2">
                  <input
                    className={fieldClass}
                    placeholder="Wpisz kod"
                    value={promoInput}
                    disabled={busy || promoBusy}
                    autoCapitalize="characters"
                    onChange={(e) => setPromoInput(e.target.value.toUpperCase())}
                  />
                  <button
                    type="button"
                    disabled={busy || promoBusy || !promoInput.trim()}
                    onClick={() => void applyCode()}
                    className="shrink-0 rounded-md border border-border px-4 text-sm font-medium hover:bg-muted/60 disabled:opacity-50"
                  >
                    {promoBusy ? 'Sprawdzanie…' : 'Zastosuj'}
                  </button>
                </div>
                {promoError ? <p className="text-xs text-destructive">{promoError}</p> : null}
              </div>

              <button
                type="button"
                disabled={busy}
                onClick={() => void confirmPay()}
                className="w-full rounded-md px-4 py-3 text-sm font-medium gradient-brand text-primary-foreground disabled:opacity-50 inline-flex items-center justify-center gap-2"
              >
                <Lock className="h-4 w-4" />
                {busy ? 'Przetwarzanie…' : `Potwierdź i zapłać · ${formatMoneyPln(payable)}`}
              </button>
              <p className="text-xs text-center text-muted-foreground">Płatność jest bezpieczna i szyfrowana SSL.</p>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
