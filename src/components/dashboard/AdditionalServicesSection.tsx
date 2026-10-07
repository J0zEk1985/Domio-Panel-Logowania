import { useEffect } from 'react'
import { Link } from 'react-router-dom'
import { Sparkles } from 'lucide-react'
import { usePricingPlans } from '../../hooks/useMonetization'

function formatPrice(price: number): string {
  return `${price.toFixed(2)} zł`
}

export function AdditionalServicesSection() {
  const { plans, fetchPlans } = usePricingPlans('developer_warranty', true)

  useEffect(() => {
    void fetchPlans()
  }, [fetchPlans])

  const plan = plans.find((row) => row.is_active) ?? null
  const priceHint = plan?.price_monthly
    ? `od ${formatPrice(plan.price_monthly)} / mies.`
    : plan?.price_yearly
      ? `od ${formatPrice(plan.price_yearly)} / rok`
      : 'Wykup, aby aktywować tę funkcję w Administracji.'

  return (
    <section id="uslugi-dodatkowe" className="mb-12" aria-labelledby="additional-services-heading">
      <h2 id="additional-services-heading" className="font-display text-xl font-semibold mb-4 flex items-center gap-2">
        <Sparkles className="h-5 w-5 text-accent" aria-hidden />
        Usługi dodatkowe
      </h2>
      <div className="grid sm:grid-cols-2 gap-4">
        <div className="bento-card relative overflow-hidden">
          <h3 className="font-display font-semibold mb-1">Usterki deweloperskie</h3>
          <p className="text-sm text-muted-foreground mb-1">
            Rejestr usterek objętych rękojmią, zaproszenie dewelopera i podgląd dla mieszkańców w DOMIO Home.
          </p>
          <p className="text-sm font-medium text-foreground mb-1">Dotyczy modułu: Domio Administracja</p>
          <p className="text-sm text-muted-foreground mb-3">{priceHint}</p>
          <Link
            to="/subscriptions?focus=developer_warranty"
            className="inline-flex h-9 items-center justify-center rounded-md border border-border px-4 text-sm font-medium hover:bg-muted/60"
          >
            Wykup usługę
          </Link>
        </div>
      </div>
    </section>
  )
}
