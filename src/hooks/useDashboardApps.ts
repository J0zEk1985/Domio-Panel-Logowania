import { useCallback, useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import type { Application } from '../types/database'
import { buildChangePasswordPath, resolvePostLoginTarget } from '../lib/postLoginRedirect'
import {
  filterAppsByOrgAccess,
  filterHubApplications,
  isSubscriptionCurrent,
  sortApplicationsByCatalog,
} from '../lib/moduleAccess'
import {
  isBillingManagerRole,
  mapPricingPlanRow,
  pickBillingMembership,
  type OrgSubscriptionView,
} from '../lib/orgBilling'
import type { PricingPlanView } from '../lib/pricingDisplay'

export function useDashboardApps() {
  const [apps, setApps] = useState<Application[]>([])
  const [allProductApps, setAllProductApps] = useState<Application[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isPlatformAdmin, setIsPlatformAdmin] = useState(false)
  const [billingOrgId, setBillingOrgId] = useState<string | null>(null)
  const [canManageBilling, setCanManageBilling] = useState(false)
  const [subsByAppId, setSubsByAppId] = useState<Map<string, OrgSubscriptionView>>(new Map())
  const [plansByAppId, setPlansByAppId] = useState<Map<string, PricingPlanView[]>>(new Map())
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()

  const loadUserApps = useCallback(async () => {
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser()

      if (!user) {
        navigate('/login')
        return
      }

      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('fleet_role, is_first_login, platform_role')
        .eq('id', user.id)
        .maybeSingle()

      if (profileError) {
        console.error('[SSO] Profile fetch error (fleet_role):', profileError.message)
      }

      const returnTo = searchParams.get('returnTo')
      if (profile?.is_first_login === true) {
        navigate(buildChangePasswordPath(returnTo))
        return
      }

      if (returnTo) {
        const target = resolvePostLoginTarget(returnTo)
        if (target.startsWith('http')) {
          window.location.href = target
        } else {
          navigate(target, { replace: true })
        }
        return
      }

      const fleetRole = profile?.fleet_role ?? null

      const { data: membershipsData, error: membershipsError } = await supabase
        .from('memberships')
        .select('role, org_id')
        .eq('user_id', user.id)

      if (membershipsError) {
        console.error('[SSO] Memberships fetch error:', membershipsError.message)
      }
      const memberships = membershipsData ?? []
      const billingMembership = pickBillingMembership(memberships)
      const nextBillingOrgId = billingMembership?.org_id ?? null
      const platformAdmin = (profile?.platform_role ?? '').toString().toLowerCase() === 'admin'
      const nextCanManage = Boolean(
        nextBillingOrgId && (isBillingManagerRole(billingMembership?.role) || platformAdmin),
      )

      const hasFleetAccess = fleetRole === 'admin' || fleetRole === 'driver'
      const hasCleaningAccess = memberships.length > 0

      if (hasFleetAccess && !hasCleaningAccess) {
        window.location.href = 'https://flota.domio.com.pl'
        return
      }

      const { data: appsData, error: appsError } = await supabase
        .from('applications')
        .select('*')
        .eq('is_active', true)
        .order('name', { ascending: true })

      if (appsError) throw appsError

      const [subsRes, plansRes] = await Promise.all([
        nextBillingOrgId
          ? supabase
              .from('org_subscriptions')
              .select('id, org_id, app_id, status, expires_at, plan_id, billing_interval, cancelled_at')
              .eq('org_id', nextBillingOrgId)
          : Promise.resolve({ data: [] as OrgSubscriptionView[], error: null }),
        supabase
          .from('pricing_plans')
          .select(
            'id, app_id, name, price_monthly, price_yearly, features, is_active, max_users, max_locations, max_storage_gb, has_ai_features',
          )
          .eq('is_active', true),
      ])

      if (subsRes.error) {
        console.error('[SSO] org_subscriptions:', subsRes.error.message)
      }
      if (plansRes.error) {
        console.error('[DashboardPage] pricing_plans:', plansRes.error.message)
      }

      const subsList = (subsRes.data ?? []) as OrgSubscriptionView[]
      const nextSubs = new Map<string, OrgSubscriptionView>()
      for (const row of subsList) {
        if (!nextSubs.has(row.app_id)) nextSubs.set(row.app_id, row)
      }

      const nextPlans = new Map<string, PricingPlanView[]>()
      for (const row of plansRes.data ?? []) {
        const plan = mapPricingPlanRow(row)
        const list = nextPlans.get(plan.app_id) ?? []
        list.push(plan)
        nextPlans.set(plan.app_id, list)
      }
      for (const [appId, list] of nextPlans) {
        nextPlans.set(
          appId,
          [...list].sort((a, b) => a.price_monthly - b.price_monthly),
        )
      }

      const subscribedAppIds = new Set(
        subsList.filter((row) => isSubscriptionCurrent(row.status, row.expires_at)).map((row) => row.app_id),
      )

      const productApps = sortApplicationsByCatalog(
        filterHubApplications(appsData || [], {
          membershipRoles: memberships.map((row) => row.role),
          fleetRole,
        }),
      )

      setIsPlatformAdmin(platformAdmin)
      setBillingOrgId(nextBillingOrgId)
      setCanManageBilling(nextCanManage)
      setSubsByAppId(nextSubs)
      setPlansByAppId(nextPlans)
      setAllProductApps(productApps)
      setApps(
        filterAppsByOrgAccess(productApps, {
          isPlatformAdmin: platformAdmin,
          subscribedAppIds,
        }),
      )
    } catch (err) {
      if (err instanceof Error && err.name === 'AbortError') {
        console.log('[DashboardPage] Request aborted (tab suspended)')
      } else {
        console.error('Error loading apps:', err)
        setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas ładowania aplikacji')
      }
    } finally {
      setLoading(false)
    }
  }, [navigate, searchParams])

  useEffect(() => {
    void loadUserApps()
  }, [loadUserApps])

  return {
    apps,
    setApps,
    allProductApps,
    loading,
    error,
    isPlatformAdmin,
    billingOrgId,
    canManageBilling,
    subsByAppId,
    setSubsByAppId,
    plansByAppId,
  }
}
