/**
 * useMonetization Hook
 * 
 * React hooks for DOMIO monetization system
 * Connects to Supabase Edge Functions for pricing, subscriptions, and access control
 */

import { useState, useCallback } from 'react'
import { supabase } from '../lib/supabase'
import type {
  PricingPlan,
  ModuleSubscription,
  CalculatePriceResponse,
  PurchaseSubscriptionRequest,
  PurchaseSubscriptionResponse,
  CheckAccessInput,
  CheckAccessResult,
  CreatePricingPlanInput,
  BillingInterval,
  AppModule,
} from '../types/monetization'

// ============================================================================
// API CLIENT
// ============================================================================

class MonetizationApiClient {
  private async callFunction<T = any>(
    functionName: string,
    options: {
      method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH'
      body?: any
      query?: Record<string, string>
    } = {}
  ): Promise<{ data: T | null; error: string | null }> {
    try {
      const { method = 'GET', body, query } = options

      // Build URL with query params
      let url = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/${functionName}`
      if (query && Object.keys(query).length > 0) {
        const params = new URLSearchParams(query)
        url += `?${params.toString()}`
      }

      const {
        data: { session },
      } = await supabase.auth.getSession()

      if (!session?.access_token) {
        return { data: null, error: 'Brak autoryzacji' }
      }

      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${session.access_token}`,
        },
        body: body ? JSON.stringify(body) : undefined,
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: response.statusText }))
        return { data: null, error: errorData.error || `HTTP ${response.status}` }
      }

      const data = await response.json()
      return { data, error: null }
    } catch (err) {
      console.error(`[MonetizationAPI] ${functionName} error:`, err)
      return {
        data: null,
        error: err instanceof Error ? err.message : 'Nieznany błąd',
      }
    }
  }

  // ========== PRICING PLANS ==========

  async getPricingPlans(params?: {
    module?: AppModule
    is_active?: boolean
  }): Promise<{ data: PricingPlan[] | null; error: string | null }> {
    const query: Record<string, string> = {}
    if (params?.module) query.module = params.module
    if (params?.is_active !== undefined) query.is_active = String(params.is_active)

    return this.callFunction<PricingPlan[]>('pricing-plans', { query })
  }

  async getPricingPlan(id: string): Promise<{ data: PricingPlan | null; error: string | null }> {
    return this.callFunction<PricingPlan>('pricing-plans', { query: { id } })
  }

  async createPricingPlan(
    input: CreatePricingPlanInput
  ): Promise<{ data: PricingPlan | null; error: string | null }> {
    return this.callFunction<PricingPlan>('pricing-plans', {
      method: 'POST',
      body: input,
    })
  }

  async updatePricingPlan(
    id: string,
    input: Partial<CreatePricingPlanInput>
  ): Promise<{ data: PricingPlan | null; error: string | null }> {
    return this.callFunction<PricingPlan>('pricing-plans', {
      method: 'PUT',
      body: { ...input, id },
    })
  }

  async deletePricingPlan(id: string): Promise<{ data: void | null; error: string | null }> {
    return this.callFunction('pricing-plans', {
      method: 'DELETE',
      query: { id },
    })
  }

  // ========== PRICE CALCULATION ==========

  async calculatePrice(params: {
    plan_id: string
    billing_interval: BillingInterval
    unit_count?: number
  }): Promise<{ data: CalculatePriceResponse | null; error: string | null }> {
    const query: Record<string, string> = {
      plan_id: params.plan_id,
      billing_interval: params.billing_interval,
    }
    if (params.unit_count !== undefined) {
      query.unit_count = String(params.unit_count)
    }

    return this.callFunction<CalculatePriceResponse>('calculate-price', { query })
  }

  // ========== SUBSCRIPTIONS ==========

  async getSubscriptions(params?: {
    org_id?: string
    community_id?: string
    module?: AppModule
    status?: string
  }): Promise<{ data: ModuleSubscription[] | null; error: string | null }> {
    const query: Record<string, string> = {}
    if (params?.org_id) query.org_id = params.org_id
    if (params?.community_id) query.community_id = params.community_id
    if (params?.module) query.module = params.module
    if (params?.status) query.status = params.status

    return this.callFunction<ModuleSubscription[]>('subscriptions', { query })
  }

  async getSubscription(
    id: string
  ): Promise<{ data: ModuleSubscription | null; error: string | null }> {
    return this.callFunction<ModuleSubscription>('subscriptions', { query: { id } })
  }

  async purchaseSubscription(
    request: PurchaseSubscriptionRequest
  ): Promise<{ data: PurchaseSubscriptionResponse | null; error: string | null }> {
    return this.callFunction<PurchaseSubscriptionResponse>('purchase-subscription', {
      method: 'POST',
      body: request,
    })
  }

  async cancelSubscription(
    id: string
  ): Promise<{ data: ModuleSubscription | null; error: string | null }> {
    return this.callFunction<ModuleSubscription>('subscriptions', {
      method: 'POST',
      body: { id, action: 'cancel' },
    })
  }

  async renewSubscription(
    id: string,
    billing_interval: BillingInterval
  ): Promise<{ data: ModuleSubscription | null; error: string | null }> {
    return this.callFunction<ModuleSubscription>('subscriptions', {
      method: 'POST',
      body: { id, action: 'renew', billing_interval },
    })
  }

  async upgradeSubscription(params: {
    subscription_id: string
    payment_method?: string
  }): Promise<{ data: PurchaseSubscriptionResponse | null; error: string | null }> {
    return this.callFunction<PurchaseSubscriptionResponse>('upgrade-subscription', {
      method: 'POST',
      body: params,
    })
  }

  // ========== ACCESS CONTROL ==========

  async checkAccess(
    input: CheckAccessInput
  ): Promise<{ data: CheckAccessResult | null; error: string | null }> {
    const query: Record<string, string> = {
      org_id: input.org_id,
      module: input.module,
    }
    if (input.community_id) {
      query.community_id = input.community_id
    }

    return this.callFunction<CheckAccessResult>('check-access', { query })
  }

  // ========== TRIAL GRANTS ==========

  async grantTrial(params: {
    org_id: string
    community_id?: string
    module: AppModule
    days: number
    reason: string
  }): Promise<{ data: CheckAccessResult | null; error: string | null }> {
    return this.callFunction<CheckAccessResult>('grant-trial', {
      method: 'POST',
      body: params,
    })
  }
}

// Singleton instance
export const monetizationApi = new MonetizationApiClient()

// ============================================================================
// HOOKS
// ============================================================================

/**
 * Hook for managing pricing plans (Service Owner / SuperAdmin)
 */
export function usePricingPlans(module?: AppModule, isActive?: boolean) {
  const [plans, setPlans] = useState<PricingPlan[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchPlans = useCallback(async () => {
    setLoading(true)
    setError(null)
    const result = await monetizationApi.getPricingPlans({ module, is_active: isActive })
    if (result.error) {
      setError(result.error)
    } else {
      setPlans(result.data ?? [])
    }
    setLoading(false)
  }, [module, isActive])

  const createPlan = useCallback(async (input: CreatePricingPlanInput) => {
    const result = await monetizationApi.createPricingPlan(input)
    if (result.error) {
      return { success: false, error: result.error }
    }
    await fetchPlans()
    return { success: true, data: result.data }
  }, [fetchPlans])

  const updatePlan = useCallback(async (id: string, input: Partial<CreatePricingPlanInput>) => {
    const result = await monetizationApi.updatePricingPlan(id, input)
    if (result.error) {
      return { success: false, error: result.error }
    }
    await fetchPlans()
    return { success: true, data: result.data }
  }, [fetchPlans])

  const deletePlan = useCallback(async (id: string) => {
    const result = await monetizationApi.deletePricingPlan(id)
    if (result.error) {
      return { success: false, error: result.error }
    }
    await fetchPlans()
    return { success: true }
  }, [fetchPlans])

  return {
    plans,
    loading,
    error,
    fetchPlans,
    createPlan,
    updatePlan,
    deletePlan,
  }
}

/**
 * Hook for managing subscriptions (Organization Admin)
 */
export function useSubscriptions(filters?: {
  org_id?: string
  community_id?: string
  module?: AppModule
  status?: string
}) {
  const [subscriptions, setSubscriptions] = useState<ModuleSubscription[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchSubscriptions = useCallback(async () => {
    setLoading(true)
    setError(null)
    const result = await monetizationApi.getSubscriptions(filters)
    if (result.error) {
      setError(result.error)
    } else {
      setSubscriptions(result.data ?? [])
    }
    setLoading(false)
  }, [filters?.org_id, filters?.community_id, filters?.module, filters?.status])

  const purchaseSubscription = useCallback(async (request: PurchaseSubscriptionRequest) => {
    const result = await monetizationApi.purchaseSubscription(request)
    if (result.error) {
      return { success: false, error: result.error }
    }
    await fetchSubscriptions()
    return { success: true, data: result.data }
  }, [fetchSubscriptions])

  const cancelSubscription = useCallback(async (id: string) => {
    const result = await monetizationApi.cancelSubscription(id)
    if (result.error) {
      return { success: false, error: result.error }
    }
    await fetchSubscriptions()
    return { success: true, data: result.data }
  }, [fetchSubscriptions])

  const renewSubscription = useCallback(async (id: string, billing_interval: BillingInterval) => {
    const result = await monetizationApi.renewSubscription(id, billing_interval)
    if (result.error) {
      return { success: false, error: result.error }
    }
    await fetchSubscriptions()
    return { success: true, data: result.data }
  }, [fetchSubscriptions])

  const upgradeSubscription = useCallback(async (subscription_id: string, payment_method?: string) => {
    const result = await monetizationApi.upgradeSubscription({ subscription_id, payment_method })
    if (result.error) {
      return { success: false, error: result.error }
    }
    await fetchSubscriptions()
    return { success: true, data: result.data }
  }, [fetchSubscriptions])

  return {
    subscriptions,
    loading,
    error,
    fetchSubscriptions,
    purchaseSubscription,
    cancelSubscription,
    renewSubscription,
    upgradeSubscription,
  }
}

/**
 * Hook for calculating prices
 */
export function usePriceCalculation() {
  const [calculating, setCalculating] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const calculatePrice = useCallback(async (params: {
    plan_id: string
    billing_interval: BillingInterval
    unit_count?: number
  }) => {
    setCalculating(true)
    setError(null)
    const result = await monetizationApi.calculatePrice(params)
    setCalculating(false)
    
    if (result.error) {
      setError(result.error)
      return { success: false, error: result.error, data: null }
    }
    
    return { success: true, data: result.data, error: null }
  }, [])

  return {
    calculatePrice,
    calculating,
    error,
  }
}

/**
 * Hook for checking module access
 */
export function useModuleAccess(params: CheckAccessInput) {
  const [hasAccess, setHasAccess] = useState<boolean | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const checkAccess = useCallback(async () => {
    setLoading(true)
    setError(null)
    const result = await monetizationApi.checkAccess(params)
    setLoading(false)
    
    if (result.error) {
      setError(result.error)
      setHasAccess(false)
    } else {
      setHasAccess(result.data?.has_access ?? false)
    }
  }, [params.org_id, params.community_id, params.module])

  return {
    hasAccess,
    loading,
    error,
    checkAccess,
  }
}
