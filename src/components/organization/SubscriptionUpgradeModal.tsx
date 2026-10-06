/**
 * SubscriptionUpgradeModal
 * 
 * Modal for upgrading blocked subscriptions
 * Calculates upgrade amount and processes payment to unblock
 */

import { useState, useEffect } from 'react'
import { X, AlertTriangle, CreditCard } from 'lucide-react'
import { toast } from 'sonner'
import { monetizationApi } from '../../hooks/useMonetization'
import type { ModuleSubscription, PricingPlan } from '../../types/monetization'
import { MODULE_DISPLAY_NAMES } from '../../types/monetization'

interface Props {
  subscription: ModuleSubscription
  isOpen: boolean
  onClose: () => void
  onSuccess: () => void
}

export default function SubscriptionUpgradeModal({ subscription, isOpen, onClose, onSuccess }: Props) {
  const [plan, setPlan] = useState<PricingPlan | null>(null)
  const [upgradeAmount, setUpgradeAmount] = useState<number | null>(null)
  const [loading, setLoading] = useState(true)
  const [processing, setProcessing] = useState(false)
  const [paymentMethod, setPaymentMethod] = useState('transfer')

  useEffect(() => {
    if (!isOpen) return

    const loadPlanAndCalculate = async () => {
      setLoading(true)

      // Fetch plan
      const planResult = await monetizationApi.getPricingPlan(subscription.plan_id)
      if (planResult.error || !planResult.data) {
        toast.error('Nie udało się pobrać planu cenowego')
        onClose()
        return
      }

      setPlan(planResult.data)

      // Calculate upgrade amount
      if (
        planResult.data.is_unit_based &&
        planResult.data.price_per_unit &&
        planResult.data.min_price &&
        subscription.paid_unit_count != null &&
        subscription.current_unit_count != null
      ) {
        const additionalUnits = subscription.current_unit_count - subscription.paid_unit_count
        if (additionalUnits > 0) {
          const newTotalPrice = Math.max(
            planResult.data.min_price,
            planResult.data.price_per_unit * subscription.current_unit_count
          )
          const upgradePrice = newTotalPrice - subscription.amount_paid
          setUpgradeAmount(Math.max(0, upgradePrice))
        } else {
          setUpgradeAmount(0)
        }
      }

      setLoading(false)
    }

    void loadPlanAndCalculate()
  }, [isOpen, subscription, onClose])

  const handleUpgrade = async () => {
    if (upgradeAmount == null || upgradeAmount <= 0) {
      toast.error('Nieprawidłowa kwota dopłaty')
      return
    }

    setProcessing(true)

    try {
      const result = await monetizationApi.upgradeSubscription({
        subscription_id: subscription.id,
        payment_method: paymentMethod,
      })

      if (result.error) {
        toast.error(result.error)
      } else {
        toast.success('Subskrypcja została odblokowana!')
        onSuccess()
      }
    } catch (err) {
      console.error('[SubscriptionUpgradeModal] upgrade error:', err)
      toast.error('Wystąpił błąd podczas dopłaty')
    } finally {
      setProcessing(false)
    }
  }

  const formatPrice = (price: number): string => {
    return `${price.toFixed(2)} zł`
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="bg-background rounded-lg shadow-xl max-w-lg w-full max-h-[90vh] overflow-auto">
        <div className="flex items-center justify-between border-b border-border p-4">
          <h3 className="text-lg font-semibold">Dopłata do subskrypcji</h3>
          <button
            onClick={onClose}
            className="text-muted-foreground hover:text-foreground"
            disabled={processing}
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {loading ? (
          <div className="p-8 text-center text-muted-foreground">Ładowanie...</div>
        ) : (
          <div className="p-6 space-y-6">
            <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 flex items-start gap-3">
              <AlertTriangle className="h-5 w-5 text-amber-600 mt-0.5 flex-shrink-0" />
              <div className="flex-1 text-sm">
                <p className="font-medium text-amber-900 mb-1">Subskrypcja wymaga dopłaty</p>
                <p className="text-amber-800">
                  Moduł <strong>{MODULE_DISPLAY_NAMES[subscription.module]}</strong> został zablokowany,
                  ponieważ liczba lokali mieszkalnych wzrosła powyżej opłaconego limitu.
                </p>
              </div>
            </div>

            {plan && (
              <div className="space-y-4">
                <div className="border border-border rounded-lg p-4 space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Plan:</span>
                    <span className="font-medium">{plan.display_name}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Cena za lokal:</span>
                    <span className="font-medium">{formatPrice(plan.price_per_unit!)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Opłacone lokale:</span>
                    <span className="font-medium">{subscription.paid_unit_count}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Aktualne lokale:</span>
                    <span className="font-medium text-amber-600">{subscription.current_unit_count}</span>
                  </div>
                  <div className="flex justify-between border-t border-border/60 pt-3">
                    <span className="text-muted-foreground">Zapłacono wcześniej:</span>
                    <span className="font-medium">{formatPrice(subscription.amount_paid)}</span>
                  </div>
                </div>

                <div className="bg-primary/10 border border-primary/30 rounded-lg p-4">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium">Kwota dopłaty:</span>
                    <span className="text-2xl font-bold text-primary">
                      {upgradeAmount != null ? formatPrice(upgradeAmount) : '—'}
                    </span>
                  </div>
                  {upgradeAmount != null && upgradeAmount > 0 && subscription.current_unit_count != null && (
                    <p className="text-xs text-muted-foreground mt-2">
                      Nowa suma: {subscription.current_unit_count} × {formatPrice(plan.price_per_unit!)} ={' '}
                      {formatPrice(plan.price_per_unit! * subscription.current_unit_count)} (lub minimum{' '}
                      {formatPrice(plan.min_price!)})
                    </p>
                  )}
                </div>

                <div className="space-y-2">
                  <label className="block text-sm font-medium text-muted-foreground">
                    Metoda płatności
                  </label>
                  <select
                    className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                    value={paymentMethod}
                    onChange={(e) => setPaymentMethod(e.target.value)}
                    disabled={processing}
                  >
                    <option value="transfer">Przelew bankowy</option>
                    <option value="card">Karta płatnicza</option>
                    <option value="invoice">Faktura (przedpłata)</option>
                  </select>
                </div>
              </div>
            )}

            <div className="flex gap-3">
              <button
                onClick={() => void handleUpgrade()}
                disabled={processing || upgradeAmount == null || upgradeAmount <= 0}
                className="flex-1 inline-flex items-center justify-center gap-2 rounded-md bg-primary px-4 py-3 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <CreditCard className="h-4 w-4" />
                {processing ? 'Przetwarzanie...' : 'Dokonaj dopłaty'}
              </button>
              <button
                onClick={onClose}
                disabled={processing}
                className="px-4 py-3 rounded-md border border-border text-sm hover:bg-muted disabled:opacity-50"
              >
                Anuluj
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
