/**
 * PlanTermsPage
 *
 * Public-to-the-buyer view of a pricing plan's own terms.
 * Opened from the checkout "regulamin" link.
 */

import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { Navbar } from '../components/landing/Navbar'
import { Footer } from '../components/landing/Footer'
import { supabase } from '../lib/supabase'
import { MODULE_DISPLAY_NAMES, type AppModule } from '../types/monetization'

const PLAN_ID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

type PlanTermsRow = {
  display_name: string
  module: AppModule
  terms_conditions: string | null
}

export default function PlanTermsPage() {
  const { planId } = useParams()
  const [plan, setPlan] = useState<PlanTermsRow | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const loadPlanTerms = async () => {
      if (!planId || !PLAN_ID_PATTERN.test(planId)) {
        setError('Nieprawidłowy identyfikator planu.')
        setLoading(false)
        return
      }

      try {
        const { data, error: fetchError } = await supabase
          .from('module_pricing_plans')
          .select('display_name, module, terms_conditions')
          .eq('id', planId)
          .maybeSingle()

        if (fetchError) {
          console.error('[PlanTermsPage] fetch error:', fetchError)
          setError('Nie udało się załadować regulaminu usługi.')
          return
        }

        if (!data) {
          setError('Nie znaleziono regulaminu tej usługi.')
          return
        }

        setPlan(data as PlanTermsRow)
      } catch (err) {
        console.error('[PlanTermsPage] error:', err)
        setError('Wystąpił błąd podczas ładowania regulaminu usługi.')
      } finally {
        setLoading(false)
      }
    }

    void loadPlanTerms()
  }, [planId])

  const moduleLabel = plan ? MODULE_DISPLAY_NAMES[plan.module] : null
  const terms = plan?.terms_conditions?.trim() ?? ''

  return (
    <div className="min-h-screen flex flex-col">
      <Navbar />
      <main className="flex-1 container mx-auto px-4 py-8 max-w-3xl">
        <Link
          to={
            plan?.module === 'home'
              ? '/subscriptions?focus=home'
              : '/subscriptions?focus=developer_warranty'
          }
          className="mb-6 inline-flex items-center text-sm text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="mr-2 h-4 w-4" />
          Wróć do zakupu
        </Link>

        {loading ? <p className="text-muted-foreground">Ładowanie regulaminu usługi…</p> : null}

        {error ? (
          <div className="rounded-lg border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-destructive">
            {error}
          </div>
        ) : null}

        {!loading && !error && plan ? (
          <>
            <h1 className="font-display text-3xl font-bold mb-2">Regulamin usługi</h1>
            <p className="text-muted-foreground mb-8">
              {moduleLabel ? `${moduleLabel} · ` : ''}
              {plan.display_name}
            </p>
            {terms ? (
              <section className="whitespace-pre-wrap text-sm leading-relaxed">{terms}</section>
            ) : (
              <p className="text-muted-foreground">Brak opublikowanego regulaminu tej usługi.</p>
            )}
          </>
        ) : null}
      </main>
      <Footer />
    </div>
  )
}
