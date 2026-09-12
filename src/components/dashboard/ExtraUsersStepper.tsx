import { Minus, Plus } from 'lucide-react'
import {
  effectiveUserLimit,
  extraUserPriceForInterval,
  extraUsersPeriodCost,
  planAllowsExtraUsers,
  type BillingInterval,
} from '../../lib/orgBilling'
import { formatMoneyPln, type PricingPlanView } from '../../lib/pricingDisplay'

type Props = {
  plan: PricingPlanView
  interval: BillingInterval
  extraUsers: number
  savedExtraUsers: number
  canEdit: boolean
  busy: boolean
  onChange: (next: number) => void
  onSave: (next: number) => void
}

export function ExtraUsersStepper({
  plan,
  interval,
  extraUsers,
  savedExtraUsers,
  canEdit,
  busy,
  onChange,
  onSave,
}: Props) {
  const allows = planAllowsExtraUsers(plan, interval)
  if (!allows && savedExtraUsers <= 0) return null

  const unitPrice = extraUserPriceForInterval(plan, interval)
  const periodLabel = interval === 'yearly' ? 'rok' : 'mies.'
  const extraCost = extraUsersPeriodCost(extraUsers, unitPrice)
  const planPrice = interval === 'yearly' ? plan.price_yearly : plan.price_monthly
  const total = planPrice + extraCost
  const effective = effectiveUserLimit(plan.max_users, extraUsers)
  const dirty = extraUsers !== savedExtraUsers

  return (
    <section className="rounded-xl border border-border/60 p-4 space-y-3">
      <h4 className="font-display font-semibold">Dodatkowi użytkownicy</h4>
      {!allows ? (
        <div className="space-y-3">
          <p className="text-sm text-muted-foreground">
            Ten okres rozliczenia nie ma ceny dodatkowego miejsca.
            {savedExtraUsers > 0 ? ` Obecnie dokupiono ${savedExtraUsers}.` : ''}
          </p>
          {canEdit && savedExtraUsers > 0 && (
            <button
              type="button"
              disabled={busy}
              onClick={() => onSave(0)}
              className="w-full rounded-md border border-border px-4 py-2.5 text-sm font-medium hover:bg-muted/60 disabled:opacity-50"
            >
              {busy ? 'Zapisywanie…' : 'Usuń dodatkowe miejsca'}
            </button>
          )}
        </div>
      ) : (
        <>
          <p className="text-sm text-muted-foreground">
            W planie: {plan.max_users} użytk.{' '}
            {unitPrice != null ? `· +1 / ${formatMoneyPln(unitPrice)} ${periodLabel}` : ''}
          </p>
          <div className="flex items-center gap-3">
            <button
              type="button"
              disabled={!canEdit || busy || extraUsers <= 0}
              onClick={() => onChange(Math.max(0, extraUsers - 1))}
              className="inline-flex h-9 w-9 items-center justify-center rounded-md border border-border hover:bg-muted disabled:opacity-50"
              aria-label="Zmniejsz liczbę dodatkowych użytkowników"
            >
              <Minus className="h-4 w-4" />
            </button>
            <div className="min-w-[4rem] text-center">
              <p className="font-display text-xl font-semibold tabular-nums">{extraUsers}</p>
              <p className="text-xs text-muted-foreground">dodatkowych</p>
            </div>
            <button
              type="button"
              disabled={!canEdit || busy}
              onClick={() => onChange(extraUsers + 1)}
              className="inline-flex h-9 w-9 items-center justify-center rounded-md border border-border hover:bg-muted disabled:opacity-50"
              aria-label="Zwiększ liczbę dodatkowych użytkowników"
            >
              <Plus className="h-4 w-4" />
            </button>
          </div>
          <p className="text-sm text-muted-foreground">
            Łączny limit: {effective ?? 'bez limitu'}
            {extraCost > 0 ? ` · dopłata ${formatMoneyPln(extraCost)} / ${periodLabel}` : ''}
          </p>
          <p className="text-sm font-medium">
            Razem: {formatMoneyPln(total)} / {periodLabel}
          </p>
          {canEdit ? (
            <button
              type="button"
              disabled={busy || !dirty}
              onClick={() => onSave(extraUsers)}
              className="w-full rounded-md px-4 py-2.5 text-sm font-medium gradient-brand text-primary-foreground disabled:opacity-50"
            >
              {busy ? 'Zapisywanie…' : 'Zapisz dodatkowe miejsca'}
            </button>
          ) : (
            <p className="text-xs text-muted-foreground">
              Dokup miejsc może wykonać tylko właściciel firmy.
            </p>
          )}
        </>
      )}
    </section>
  )
}
