import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../../lib/supabase'
import type { Application } from '../../types/database'
import type { PricingPlanRow, PromoCodeRow } from './pricingAdminTypes'
import PricingPlansSection from './PricingPlansSection'
import PromoCodesSection from './PromoCodesSection'

export default function PricingAdminTab() {
  const [applications, setApplications] = useState<Application[]>([])
  const [plans, setPlans] = useState<PricingPlanRow[]>([])
  const [promoCodes, setPromoCodes] = useState<PromoCodeRow[]>([])
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)

  const loadAll = useCallback(async () => {
    setLoadError(null)
    try {
      const [appsRes, plansRes, promosRes] = await Promise.all([
        supabase.from('applications').select('id, name, domain_url, api_url, is_free, is_active, created_at').order('name'),
        supabase
          .from('pricing_plans')
          .select('id, app_id, name, price_monthly, price_yearly, features, is_active, created_at, updated_at, applications(name)')
          .order('name'),
        supabase.from('promo_codes').select('*').order('code'),
      ])

      if (appsRes.error) {
        console.error('[PricingAdminTab] applications:', appsRes.error)
        setLoadError('Nie udało się pobrać listy aplikacji.')
      } else {
        setApplications((appsRes.data as Application[]) ?? [])
      }

      if (plansRes.error) {
        console.error('[PricingAdminTab] pricing_plans:', plansRes.error)
        setLoadError((prev) => prev ?? 'Nie udało się pobrać planów cenowych (sprawdź migrację i RLS).')
        setPlans([])
      } else {
        setPlans((plansRes.data as unknown as PricingPlanRow[]) ?? [])
      }

      if (promosRes.error) {
        console.error('[PricingAdminTab] promo_codes:', promosRes.error)
        setLoadError((prev) => prev ?? 'Nie udało się pobrać kodów promocyjnych.')
        setPromoCodes([])
      } else {
        setPromoCodes((promosRes.data as PromoCodeRow[]) ?? [])
      }
    } catch (e) {
      console.error('[PricingAdminTab] loadAll:', e)
      setLoadError('Wystąpił nieoczekiwany błąd podczas ładowania danych.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadAll()
  }, [loadAll])

  if (loading) {
    return (
      <div className="p-6 bento-card text-muted-foreground text-center">Ładowanie cennika i promocji…</div>
    )
  }

  return (
    <div className="space-y-12">
      {loadError && (
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {loadError}
        </div>
      )}

      <PricingPlansSection applications={applications} plans={plans} onRefresh={loadAll} />
      <PromoCodesSection promoCodes={promoCodes} onRefresh={loadAll} />
    </div>
  )
}
