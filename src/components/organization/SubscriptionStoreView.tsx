/**
 * SubscriptionStoreView
 * 
 * Marketplace for purchasing module subscriptions
 * Org Admin can select community (for home), calculate price, and purchase
 */

import { useState, useEffect } from 'react'
import { ShoppingCart, Building2, AlertCircle, Check } from 'lucide-react'
import { toast } from 'sonner'
import { supabase } from '../../lib/supabase'
import { usePricingPlans, usePriceCalculation, useSubscriptions } from '../../hooks/useMonetization'
import type {
  BillingInterval,
  PurchaseSubscriptionRequest,
} from '../../types/monetization'
import { MODULE_DISPLAY_NAMES, BILLING_INTERVAL_LABELS } from '../../types/monetization'

interface Community {
  id: string
  name: string
  unit_count?: number
}

interface CommunityWithUnits extends Community {
  residential_unit_count: number
}

export default function SubscriptionStoreView() {
  const [selectedOrgId, setSelectedOrgId] = useState<string | null>(null)
  const [selectedPlanId, setSelectedPlanId] = useState<string | null>(null)
  const [selectedCommunityId, setSelectedCommunityId] = useState<string | null>(null)
  const [billingInterval, setBillingInterval] = useState<BillingInterval>('monthly')
  const [calculatedAmount, setCalculatedAmount] = useState<number | null>(null)
  const [paymentMethod, setPaymentMethod] = useState('transfer')

  const [communities, setCommunities] = useState<CommunityWithUnits[]>([])
  const [loadingCommunities, setLoadingCommunities] = useState(false)

  const { plans, loading: loadingPlans, fetchPlans } = usePricingPlans(undefined, true)
  const { calculatePrice, calculating } = usePriceCalculation()
  const { purchaseSubscription } = useSubscriptions()

  const selectedPlan = plans.find((p) => p.id === selectedPlanId)
  const selectedCommunity = communities.find((c) => c.id === selectedCommunityId)

  useEffect(() => {
    void fetchPlans()
  }, [fetchPlans])

  useEffect(() => {
    const loadUserOrg = async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) return

      const { data: memberships } = await supabase
        .from('memberships')
        .select('organization_id, role')
        .eq('user_id', user.id)
        .in('role', ['admin', 'owner'])
        .limit(1)
        .single()

      if (memberships?.organization_id) {
        setSelectedOrgId(memberships.organization_id)
      }
    }

    void loadUserOrg()
  }, [])

  useEffect(() => {
    if (!selectedOrgId) return

    const loadCommunities = async () => {
      setLoadingCommunities(true)
      const { data, error } = await supabase
        .from('communities')
        .select('id, name')
        .eq('organization_id', selectedOrgId)
        .order('name')

      if (error) {
        console.error('[SubscriptionStoreView] load communities:', error)
        toast.error('Nie udało się pobrać wspólnot')
        setLoadingCommunities(false)
        return
      }

      // Fetch residential unit counts
      const communityIds = (data ?? []).map((c) => c.id)
      if (communityIds.length === 0) {
        setCommunities([])
        setLoadingCommunities(false)
        return
      }

      // For simplicity, batch count units (in production, create a batch RPC or join)
      const communitiesWithUnits: CommunityWithUnits[] = []
      for (const comm of data ?? []) {
        const { data: count } = await supabase.rpc('count_residential_units_for_community', {
          p_community_id: comm.id,
        })
        communitiesWithUnits.push({
          ...comm,
          residential_unit_count: count ?? 0,
        })
      }

      setCommunities(communitiesWithUnits)
      setLoadingCommunities(false)
    }

    void loadCommunities()
  }, [selectedOrgId])

  useEffect(() => {
    if (!selectedPlan || !billingInterval) {
      setCalculatedAmount(null)
      return
    }

    const calculate = async () => {
      if (selectedPlan.is_unit_based && !selectedCommunity) {
        setCalculatedAmount(null)
        return
      }

      const result = await calculatePrice({
        plan_id: selectedPlan.id,
        billing_interval: billingInterval,
        unit_count: selectedPlan.is_unit_based ? selectedCommunity?.residential_unit_count : undefined,
      })

      if (result.success && result.data) {
        setCalculatedAmount(result.data.calculated_amount)
      } else {
        setCalculatedAmount(null)
      }
    }

    void calculate()
  }, [selectedPlan, selectedCommunity, billingInterval, calculatePrice])

  const handlePurchase = async () => {
    if (!selectedOrgId || !selectedPlanId || !billingInterval) {
      toast.error('Wybierz plan i okres rozliczeniowy')
      return
    }

    if (selectedPlan?.is_unit_based && !selectedCommunityId) {
      toast.error('Wybierz wspólnotę')
      return
    }

    if (calculatedAmount == null) {
      toast.error('Nie udało się obliczyć ceny')
      return
    }

    const request: PurchaseSubscriptionRequest = {
      plan_id: selectedPlanId,
      billing_interval: billingInterval,
      payment_method: paymentMethod,
    }

    if (selectedCommunityId) {
      request.beneficiary_community_id = selectedCommunityId
      request.invoice_entity_community_id = selectedCommunityId
    }

    const result = await purchaseSubscription(request)

    if (result.success) {
      toast.success('Subskrypcja została zakupiona!')
      setSelectedPlanId(null)
      setSelectedCommunityId(null)
      setCalculatedAmount(null)
    } else {
      toast.error(result.error ?? 'Nie udało się zakupić subskrypcji')
    }
  }

  const formatPrice = (price: number): string => {
    return `${price.toFixed(2)} zł`
  }

  const availablePlans = plans.filter((p) => p.is_active)

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <ShoppingCart className="h-6 w-6 text-primary" />
        <h2 className="font-display text-2xl font-semibold">Sklep z subskrypcjami</h2>
      </div>

      {loadingPlans ? (
        <div className="bento-card p-8 text-center text-muted-foreground">Ładowanie planów...</div>
      ) : availablePlans.length === 0 ? (
        <div className="bento-card p-8 text-center text-muted-foreground">
          Brak dostępnych planów cenowych. Skontaktuj się z administratorem.
        </div>
      ) : (
        <>
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
            {availablePlans.map((plan) => (
              <button
                key={plan.id}
                onClick={() => setSelectedPlanId(plan.id)}
                className={`bento-card p-4 text-left transition-all hover:shadow-lg ${
                  selectedPlanId === plan.id ? 'ring-2 ring-primary' : ''
                }`}
              >
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <h3 className="font-semibold text-lg">{plan.display_name}</h3>
                    <p className="text-sm text-muted-foreground">{MODULE_DISPLAY_NAMES[plan.module]}</p>
                  </div>
                  {selectedPlanId === plan.id && <Check className="h-5 w-5 text-primary" />}
                </div>

                {plan.description && <p className="text-sm text-muted-foreground mb-3">{plan.description}</p>}

                <div className="border-t border-border/60 pt-3 space-y-2">
                  {plan.is_unit_based ? (
                    <div className="text-sm">
                      <div className="font-medium text-primary">{formatPrice(plan.price_per_unit!)} / lokal</div>
                      <div className="text-xs text-muted-foreground">Minimalna kwota: {formatPrice(plan.min_price!)}</div>
                    </div>
                  ) : (
                    <div className="text-sm space-y-1">
                      {plan.price_monthly && (
                        <div>
                          <span className="font-medium text-primary">{formatPrice(plan.price_monthly)}</span>{' '}
                          <span className="text-muted-foreground">/ miesiąc</span>
                        </div>
                      )}
                      {plan.price_yearly && (
                        <div>
                          <span className="font-medium text-primary">{formatPrice(plan.price_yearly)}</span>{' '}
                          <span className="text-muted-foreground">/ rok</span>
                        </div>
                      )}
                    </div>
                  )}

                  {plan.is_global && (
                    <div className="flex items-center gap-1 text-xs text-primary">
                      <Building2 className="h-3 w-3" />
                      <span>Globalny (cała organizacja)</span>
                    </div>
                  )}
                </div>

                {(plan.features ?? []).length > 0 && (
                  <ul className="mt-3 space-y-1 text-xs text-muted-foreground">
                    {plan.features!.slice(0, 3).map((feature, idx) => (
                      <li key={idx} className="flex items-start gap-2">
                        <Check className="h-3 w-3 text-primary mt-0.5 flex-shrink-0" />
                        <span>{feature}</span>
                      </li>
                    ))}
                    {plan.features!.length > 3 && (
                      <li className="text-primary">+ {plan.features!.length - 3} więcej...</li>
                    )}
                  </ul>
                )}
              </button>
            ))}
          </div>

          {selectedPlan && (
            <div className="bento-card p-6 space-y-6">
              <h3 className="font-semibold text-lg">Konfiguracja zakupu: {selectedPlan.display_name}</h3>

              {selectedPlan.is_unit_based && !selectedPlan.is_global && (
                <div className="space-y-2">
                  <label className="block text-sm font-medium text-muted-foreground">
                    Wybierz wspólnotę
                  </label>
                  {loadingCommunities ? (
                    <div className="text-sm text-muted-foreground">Ładowanie wspólnot...</div>
                  ) : communities.length === 0 ? (
                    <div className="flex items-start gap-2 bg-muted/50 p-3 rounded-md text-sm">
                      <AlertCircle className="h-4 w-4 text-muted-foreground mt-0.5" />
                      <span className="text-muted-foreground">
                        Brak wspólnot w Twojej organizacji. Dodaj wspólnotę w panelu administracyjnym.
                      </span>
                    </div>
                  ) : (
                    <select
                      className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                      value={selectedCommunityId ?? ''}
                      onChange={(e) => setSelectedCommunityId(e.target.value || null)}
                    >
                      <option value="">— Wybierz wspólnotę —</option>
                      {communities.map((c) => (
                        <option key={c.id} value={c.id}>
                          {c.name} ({c.residential_unit_count} lokali mieszkalnych)
                        </option>
                      ))}
                    </select>
                  )}
                </div>
              )}

              <div className="space-y-2">
                <label className="block text-sm font-medium text-muted-foreground">
                  Okres rozliczeniowy
                </label>
                <div className="flex gap-2">
                  {(['monthly', 'yearly'] as BillingInterval[])
                    .filter((interval) => {
                      if (interval === 'monthly') return selectedPlan.price_monthly != null
                      if (interval === 'yearly') return selectedPlan.price_yearly != null
                      return false
                    })
                    .map((interval) => (
                      <button
                        key={interval}
                        onClick={() => setBillingInterval(interval)}
                        className={`flex-1 px-4 py-2 rounded-md border text-sm font-medium transition-all ${
                          billingInterval === interval
                            ? 'bg-primary text-primary-foreground border-primary'
                            : 'bg-background border-input hover:bg-muted'
                        }`}
                      >
                        {BILLING_INTERVAL_LABELS[interval]}
                      </button>
                    ))}
                </div>
              </div>

              <div className="space-y-2">
                <label className="block text-sm font-medium text-muted-foreground">
                  Metoda płatności
                </label>
                <select
                  className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  value={paymentMethod}
                  onChange={(e) => setPaymentMethod(e.target.value)}
                >
                  <option value="transfer">Przelew bankowy</option>
                  <option value="card">Karta płatnicza</option>
                  <option value="invoice">Faktura (przedpłata)</option>
                </select>
              </div>

              {calculatedAmount != null && (
                <div className="bg-primary/10 border border-primary/30 rounded-lg p-4">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium">Kwota do zapłaty:</span>
                    <span className="text-2xl font-bold text-primary">{formatPrice(calculatedAmount)}</span>
                  </div>
                  {selectedPlan.is_unit_based && selectedCommunity && (
                    <p className="text-xs text-muted-foreground mt-2">
                      {selectedCommunity.residential_unit_count} lokali × {formatPrice(selectedPlan.price_per_unit!)} ={' '}
                      {formatPrice(selectedPlan.price_per_unit! * selectedCommunity.residential_unit_count)}, minimum:{' '}
                      {formatPrice(selectedPlan.min_price!)}
                    </p>
                  )}
                </div>
              )}

              <button
                onClick={() => void handlePurchase()}
                disabled={
                  calculating ||
                  calculatedAmount == null ||
                  (selectedPlan.is_unit_based && !selectedCommunityId)
                }
                className="w-full rounded-md bg-primary px-4 py-3 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {calculating ? 'Obliczanie...' : 'Zakup subskrypcję'}
              </button>
            </div>
          )}
        </>
      )}
    </div>
  )
}
