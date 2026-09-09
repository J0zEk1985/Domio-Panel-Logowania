import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import { CheckCircle2, Star } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { parseFeaturesFromDb } from '../admin/pricingAdminUtils'

export interface PricingPlan {
  id: string
  name: string
  monthlyPrice: number
  yearlyPrice: number
  features: string[]
  highlighted?: boolean
}

type DbPricingPlanRow = {
  id: string
  app_id: string
  name: string
  price_monthly: number
  price_yearly: number
  features: unknown
  is_active: boolean
  max_users: number | null
  max_locations: number | null
  max_storage_gb: number | null
  has_ai_features: boolean | null
}

type ApplicationRow = { id: string; name: string }

function matchesModuleApplication(appName: string, moduleName: string, moduleSlug: string): boolean {
  const a = appName.trim().toLowerCase()
  const m = moduleName.trim().toLowerCase()
  if (a === m) return true
  const slugHints: Record<string, string[]> = {
    cleaning: ['cleaning'],
    flota: ['flota'],
    serwis: ['serwis'],
    administracja: ['administrac', 'nieruchomo'],
    home: ['home', 'mieszkan'],
  }
  const hints = slugHints[moduleSlug]
  if (hints?.some((h) => a.includes(h))) return true
  const first = m.split(/\s+/)[0]
  if (first.length >= 4 && a.includes(first)) return true
  return false
}

function limitFeatureLines(row: DbPricingPlanRow): string[] {
  const lines: string[] = []
  if (row.max_users != null) {
    lines.push(row.max_users === 0 ? 'Bez użytkowników' : `Do ${row.max_users} użytkowników`)
  } else {
    lines.push('Użytkownicy bez limitu')
  }
  if (row.max_locations != null) {
    lines.push(`Do ${row.max_locations} lokalizacji`)
  }
  if (row.max_storage_gb != null) {
    lines.push(`${row.max_storage_gb} GB pamięci`)
  }
  if (row.has_ai_features === true) {
    lines.push('Dostęp do funkcji AI')
  }
  return lines
}

function toDisplayPlan(row: DbPricingPlanRow, highlighted: boolean): PricingPlan {
  const fromDb = parseFeaturesFromDb(row.features)
  return {
    id: row.id,
    name: row.name,
    monthlyPrice: Number(row.price_monthly) || 0,
    yearlyPrice: Number(row.price_yearly) || 0,
    features: [...limitFeatureLines(row), ...fromDb],
    highlighted,
  }
}

interface PricingSectionProps {
  moduleName: string
  moduleSlug: string
}

export function PricingSection({ moduleName, moduleSlug }: PricingSectionProps) {
  const [yearly, setYearly] = useState(false)
  const [dbPlans, setDbPlans] = useState<DbPricingPlanRow[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false

    const load = async () => {
      setLoading(true)
      const plansRes = await supabase
        .from('pricing_plans')
        .select(
          'id, app_id, name, price_monthly, price_yearly, features, is_active, max_users, max_locations, max_storage_gb, has_ai_features',
        )
        .eq('is_active', true)

      if (cancelled) return

      if (plansRes.error) {
        console.error('[PricingSection] pricing_plans:', plansRes.error)
        setDbPlans([])
        setLoading(false)
        return
      }

      const rows = (plansRes.data as DbPricingPlanRow[]) ?? []
      const appIds = [...new Set(rows.map((r) => r.app_id))]
      if (appIds.length === 0) {
        setDbPlans([])
        setLoading(false)
        return
      }

      const appsRes = await supabase.from('applications').select('id, name').in('id', appIds)

      if (cancelled) return

      if (appsRes.error) {
        console.error('[PricingSection] applications:', appsRes.error)
        setDbPlans([])
        setLoading(false)
        return
      }

      const apps = (appsRes.data as ApplicationRow[]) ?? []
      const app = apps.find((row) => matchesModuleApplication(row.name, moduleName, moduleSlug))
      setDbPlans(app ? rows.filter((p) => p.app_id === app.id) : [])
      setLoading(false)
    }

    void load()
    return () => {
      cancelled = true
    }
  }, [moduleName, moduleSlug])

  const displayPlans = useMemo(() => {
    const sorted = [...dbPlans].sort((a, b) => Number(a.price_monthly) - Number(b.price_monthly))
    const highlightId =
      sorted.length >= 2 ? sorted[Math.min(1, sorted.length - 1)]?.id : sorted[0]?.id
    return sorted.map((row) => toDisplayPlan(row, row.id === highlightId && sorted.length > 1))
  }, [dbPlans])

  return (
    <section className="py-20 px-4">
      <div className="container mx-auto max-w-6xl">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-12"
        >
          <h2 className="font-display text-3xl md:text-4xl font-bold mb-4">
            Wybierz swój <span className="gradient-brand-text">plan</span>
          </h2>
          <p className="text-muted-foreground max-w-md mx-auto mb-8">
            Ceny i limity pochodzą z ustawień administratora platformy.
          </p>
          {displayPlans.length > 0 && (
            <div className="flex items-center justify-center gap-3" role="group" aria-label="Okres rozliczenia">
              <span className={`text-sm ${!yearly ? 'text-foreground' : 'text-muted-foreground'}`}>Miesięcznie</span>
              <button
                id="billing-toggle"
                type="button"
                role="switch"
                aria-checked={yearly}
                onClick={() => setYearly((v) => !v)}
                className={`relative h-7 w-12 rounded-full transition-colors ${yearly ? 'bg-primary' : 'bg-muted'}`}
              >
                <span
                  className={`absolute top-0.5 left-0.5 h-6 w-6 rounded-full bg-background shadow transition-transform ${yearly ? 'translate-x-5' : 'translate-x-0'}`}
                />
              </button>
              <span className={`text-sm ${yearly ? 'text-foreground' : 'text-muted-foreground'}`}>Rocznie</span>
            </div>
          )}
        </motion.div>

        {loading && <p className="text-center text-muted-foreground">Ładowanie planów…</p>}

        {!loading && displayPlans.length === 0 && (
          <div className="bento-card max-w-xl mx-auto text-center">
            <p className="text-muted-foreground mb-4">
              Brak opublikowanych planów dla tego modułu. Administrator ustawia je w panelu platformy, a dostęp
              włącza per organizacja.
            </p>
            <Link
              to="/dashboard"
              className="inline-flex items-center justify-center rounded-md px-6 py-3 text-sm font-medium gradient-brand text-primary-foreground"
            >
              Przejdź do panelu
            </Link>
          </div>
        )}

        {!loading && displayPlans.length > 0 && (
          <motion.div
            initial="hidden"
            whileInView="show"
            viewport={{ once: true, amount: 0.2 }}
            variants={{ hidden: { opacity: 0 }, show: { opacity: 1, transition: { staggerChildren: 0.1 } } }}
            className={`grid grid-cols-1 gap-6 ${displayPlans.length >= 3 ? 'md:grid-cols-3' : displayPlans.length === 2 ? 'md:grid-cols-2 max-w-3xl mx-auto' : 'max-w-md mx-auto'}`}
          >
            {displayPlans.map((plan) => {
              const price = yearly ? plan.yearlyPrice : plan.monthlyPrice
              return (
                <motion.div
                  key={plan.id}
                  variants={{ hidden: { opacity: 0, y: 30 }, show: { opacity: 1, y: 0 } }}
                  whileHover={{ y: -6, scale: 1.02 }}
                  className={`bento-card relative flex flex-col ${
                    plan.highlighted ? 'ring-2 ring-primary/60 shadow-[0_0_40px_-10px_hsl(var(--primary)/0.3)]' : ''
                  }`}
                >
                  {plan.highlighted && (
                    <div className="absolute -top-3 left-1/2 -translate-x-1/2 flex items-center gap-1 px-3 py-1 rounded-full bg-primary text-primary-foreground text-xs font-semibold">
                      <Star className="h-3 w-3" /> Polecany
                    </div>
                  )}
                  <div className="mb-4">
                    <h3 className="font-display text-xl font-bold mb-1">{plan.name}</h3>
                    <p className="text-sm text-muted-foreground">{moduleName}</p>
                  </div>
                  <div className="mb-6">
                    <span className="font-display text-4xl font-bold">{price} zł</span>
                    <span className="text-muted-foreground text-sm ml-1">/ {yearly ? 'rok' : 'mies.'}</span>
                  </div>
                  <ul className="space-y-3 mb-8 flex-1">
                    {plan.features.map((f) => (
                      <li key={f} className="flex items-start gap-2 text-sm text-muted-foreground">
                        <CheckCircle2 className="h-4 w-4 text-primary shrink-0 mt-0.5" />
                        <span>{f}</span>
                      </li>
                    ))}
                  </ul>
                  <Link
                    to="/dashboard"
                    className={`w-full rounded-md px-4 py-3 text-sm font-medium text-center transition-colors ${
                      plan.highlighted
                        ? 'gradient-brand text-primary-foreground border-0'
                        : 'border border-border bg-background hover:bg-muted/60'
                    }`}
                  >
                    Przejdź do panelu
                  </Link>
                </motion.div>
              )
            })}
          </motion.div>
        )}
      </div>
    </section>
  )
}
