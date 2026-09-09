import { useMemo, useState } from 'react'
import { CheckCircle2, X } from 'lucide-react'
import { toast } from 'sonner'
import {
  activateOrgSubscriptionPlan,
  cancelOrgSubscription,
  currentPlanForApp,
  isOrgSubscriptionActive,
  upgradePlansFor,
  type BillingInterval,
  type OrgSubscriptionView,
} from '../../lib/orgBilling'
import {
  formatDatePl,
  planLimitLines,
  planPriceLabel,
  type PricingPlanView,
} from '../../lib/pricingDisplay'

type Props = {
  appName: string
  appId: string
  orgId: string
  canManage: boolean
  subscription: OrgSubscriptionView | null
  plans: PricingPlanView[]
  onClose: () => void
  onChanged: (next: OrgSubscriptionView) => void
}

function PlanFeatureList({ plan }: { plan: PricingPlanView }) {
  const lines = [...planLimitLines(plan), ...plan.features]
  return (
    <ul className="space-y-2">
      {lines.map((line) => (
        <li key={line} className="flex items-start gap-2 text-sm text-muted-foreground">
          <CheckCircle2 className="h-4 w-4 text-primary shrink-0 mt-0.5" aria-hidden />
          <span>{line}</span>
        </li>
      ))}
    </ul>
  )
}

export function ModulePlanDialog({
  appName,
  appId,
  orgId,
  canManage,
  subscription,
  plans,
  onClose,
  onChanged,
}: Props) {
  const active = isOrgSubscriptionActive(subscription)
  const current = currentPlanForApp(plans, subscription)
  const upgrades = upgradePlansFor(plans, active ? current : null)
  const purchasePlans = active ? upgrades : [...plans].sort((a, b) => a.price_monthly - b.price_monthly)

  const [yearly, setYearly] = useState(subscription?.billing_interval === 'yearly')
  const [selectedPlanId, setSelectedPlanId] = useState(purchasePlans[0]?.id ?? '')
  const [confirmCancel, setConfirmCancel] = useState(false)
  const [busy, setBusy] = useState(false)

  const selected = useMemo(
    () => purchasePlans.find((plan) => plan.id === selectedPlanId) ?? purchasePlans[0] ?? null,
    [purchasePlans, selectedPlanId],
  )

  const activate = async () => {
    if (!selected) return
    setBusy(true)
    try {
      const interval: BillingInterval = yearly ? 'yearly' : 'monthly'
      const next = await activateOrgSubscriptionPlan({
        orgId,
        appId,
        planId: selected.id,
        billingInterval: interval,
      })
      toast.success(active ? 'Plan został zmieniony.' : 'Plan został aktywowany.')
      onChanged(next)
      onClose()
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Nie udało się zapisać planu.')
    } finally {
      setBusy(false)
    }
  }

  const resign = async () => {
    setBusy(true)
    try {
      const next = await cancelOrgSubscription({ orgId, appId })
      toast.success('Zrezygnowano z planu. Dostęp do modułu został wyłączony.')
      onChanged(next)
      onClose()
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Nie udało się zrezygnować z planu.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
      role="dialog"
      aria-modal="true"
      aria-labelledby="module-plan-title"
      onClick={onClose}
    >
      <div
        className="bento-card max-w-lg w-full max-h-[85vh] flex flex-col shadow-lg border border-border"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between gap-4 p-4 border-b border-border/60">
          <div>
            <h3 id="module-plan-title" className="font-display font-semibold text-lg">
              Plan — {appName}
            </h3>
            <p className="text-xs text-muted-foreground mt-1">
              {active && current
                ? `Aktualny plan: ${current.name}`
                : active
                  ? 'Subskrypcja aktywna bez przypisanego planu'
                  : 'Brak aktywnego planu'}
            </p>
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

        <div className="overflow-y-auto p-4 space-y-6 flex-1">
          {current && (
            <section className="rounded-xl border border-border/60 bg-muted/20 p-4 space-y-3">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <p className="font-display font-semibold">{current.name}</p>
                  <p className="text-sm text-muted-foreground">
                    {planPriceLabel(current, subscription?.billing_interval === 'yearly')}
                  </p>
                </div>
                {active && (
                  <span className="inline-flex items-center rounded-md border px-2 py-0.5 text-xs font-medium bg-primary/10 text-primary border-primary/20">
                    Aktualny
                  </span>
                )}
              </div>
              {active && (
                <p className="text-xs text-muted-foreground">Wygasa: {formatDatePl(subscription?.expires_at)}</p>
              )}
              <PlanFeatureList plan={current} />
            </section>
          )}

          {plans.length === 0 && (
            <p className="text-sm text-muted-foreground">
              Brak opublikowanych planów dla tego modułu. Skontaktuj się z administratorem platformy.
            </p>
          )}

          {canManage && purchasePlans.length > 0 && (
            <section className="space-y-4">
              <h4 className="font-display font-semibold">
                {active ? 'Większy plan' : 'Wybierz plan'}
              </h4>
              <div className="flex items-center gap-3" role="group" aria-label="Okres rozliczenia">
                <span className={`text-sm ${!yearly ? 'text-foreground' : 'text-muted-foreground'}`}>Miesięcznie</span>
                <button
                  type="button"
                  role="switch"
                  aria-checked={yearly}
                  disabled={busy}
                  onClick={() => setYearly((v) => !v)}
                  className={`relative h-7 w-12 rounded-full transition-colors ${yearly ? 'bg-primary' : 'bg-muted'}`}
                >
                  <span
                    className={`absolute top-0.5 left-0.5 h-6 w-6 rounded-full bg-background shadow transition-transform ${yearly ? 'translate-x-5' : 'translate-x-0'}`}
                  />
                </button>
                <span className={`text-sm ${yearly ? 'text-foreground' : 'text-muted-foreground'}`}>Rocznie</span>
              </div>
              <div className="space-y-2">
                {purchasePlans.map((plan) => {
                  const checked = (selected?.id ?? '') === plan.id
                  return (
                    <label
                      key={plan.id}
                      className={`flex cursor-pointer items-start gap-3 rounded-xl border p-3 ${
                        checked ? 'border-primary bg-primary/5' : 'border-border/60'
                      }`}
                    >
                      <input
                        type="radio"
                        name="module-plan"
                        className="mt-1"
                        checked={checked}
                        disabled={busy}
                        onChange={() => setSelectedPlanId(plan.id)}
                      />
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between gap-2">
                          <span className="font-medium">{plan.name}</span>
                          <span className="text-sm text-muted-foreground">{planPriceLabel(plan, yearly)}</span>
                        </div>
                      </div>
                    </label>
                  )
                })}
              </div>
              {selected && <PlanFeatureList plan={selected} />}
              <p className="text-xs text-muted-foreground">
                Aktywacja przypisuje plan do organizacji. Płatność online nie jest pobierana w tym kroku.
              </p>
              <button
                type="button"
                disabled={busy || !selected}
                onClick={() => void activate()}
                className="w-full rounded-md px-4 py-3 text-sm font-medium gradient-brand text-primary-foreground disabled:opacity-50"
              >
                {busy ? 'Zapisywanie…' : active ? 'Zmień na większy plan' : 'Aktywuj plan'}
              </button>
            </section>
          )}

          {canManage && active && purchasePlans.length === 0 && plans.length > 0 && (
            <p className="text-sm text-muted-foreground">Korzystasz już z najdroższego opublikowanego planu.</p>
          )}

          {canManage && active && (
            <section className="border-t border-border/60 pt-4 space-y-3">
              {!confirmCancel ? (
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => setConfirmCancel(true)}
                  className="w-full rounded-md border border-destructive/40 px-4 py-2.5 text-sm font-medium text-destructive hover:bg-destructive/10 disabled:opacity-50"
                >
                  Zrezygnuj z planu
                </button>
              ) : (
                <div className="space-y-3">
                  <p className="text-sm text-muted-foreground">
                    Rezygnacja jest natychmiastowa. Organizacja straci dostęp do tego modułu.
                  </p>
                  <div className="flex gap-2">
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => setConfirmCancel(false)}
                      className="flex-1 rounded-md border border-border px-4 py-2.5 text-sm font-medium hover:bg-muted/60"
                    >
                      Anuluj
                    </button>
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => void resign()}
                      className="flex-1 rounded-md bg-destructive text-destructive-foreground px-4 py-2.5 text-sm font-medium disabled:opacity-50"
                    >
                      {busy ? 'Zapisywanie…' : 'Potwierdź rezygnację'}
                    </button>
                  </div>
                </div>
              )}
            </section>
          )}

          {!canManage && (
            <p className="text-sm text-muted-foreground">
              Zmianę planu może wykonać właściciel lub administrator organizacji.
            </p>
          )}
        </div>
      </div>
    </div>
  )
}
