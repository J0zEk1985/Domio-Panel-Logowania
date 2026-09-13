import { supabase } from '../../lib/supabase'
import {
  filterAppsByOrgAccess,
  filterHubApplications,
  isSubscriptionCurrent,
  moduleSlugForApplication,
  sortApplicationsByCatalog,
} from '../../lib/moduleAccess'
import type { Application } from '../../types/database'
import { membershipRoleLabel } from './usersAndOrgsUtils'

export type ProductAppOption = {
  id: string
  name: string
  is_free: boolean | null
  domain_url: string | null
  api_url: string | null
}

export type UserModuleAccessRow = {
  id: string
  name: string
  hasAccess: boolean
  reason: string
}

const CLEANING_MEMBERSHIP_ROLES = [
  'cleaner',
  'staff',
  'coordinator',
  'koordynator',
  'owner',
  'wlasciciel',
  'admin',
  'administrator',
  'manager',
]

const SERWIS_MEMBERSHIP_ROLES = ['technik']

const ADMINISTRACJA_MEMBERSHIP_ROLES = [
  'owner',
  'wlasciciel',
  'admin',
  'administrator',
  'coordinator',
  'koordynator',
  'manager',
]

export function productAppSlug(app: Pick<ProductAppOption, 'name' | 'domain_url' | 'api_url'>): string | null {
  return (
    moduleSlugForApplication({
      name: app.name,
      domain_url: app.domain_url ?? '',
      api_url: app.api_url,
    }) ?? null
  )
}

function toApplication(app: ProductAppOption): Application {
  return {
    id: app.id,
    name: app.name,
    domain_url: app.domain_url ?? '',
    api_url: app.api_url,
    is_free: app.is_free === true,
    is_active: true,
    created_at: '',
  }
}

function inferredReasonForSlug(
  slug: string,
  opts: { membershipRoles: string[]; fleetRole: string | null; isPlatformAdmin: boolean },
): string | null {
  const roles = opts.membershipRoles.map((r) => r.trim().toLowerCase())
  if (opts.isPlatformAdmin) return 'Administrator platformy'
  if (slug === 'flota' && (opts.fleetRole === 'admin' || opts.fleetRole === 'driver')) {
    return 'Rola we flocie'
  }
  if (slug === 'serwis' && roles.some((r) => SERWIS_MEMBERSHIP_ROLES.includes(r))) {
    const role = opts.membershipRoles.find((r) => SERWIS_MEMBERSHIP_ROLES.includes(r.trim().toLowerCase()))
    return `Rola w firmie: ${membershipRoleLabel(role ?? 'technik')}`
  }
  if (slug === 'cleaning' && roles.some((r) => CLEANING_MEMBERSHIP_ROLES.includes(r))) {
    return 'Rola w firmie (Cleaning)'
  }
  if (slug === 'administracja' && roles.some((r) => ADMINISTRACJA_MEMBERSHIP_ROLES.includes(r))) {
    return 'Rola zarządzająca w firmie'
  }
  return null
}

export function computeUserModuleAccess(opts: {
  applications: ProductAppOption[]
  membershipRoles: string[]
  fleetRole: string | null
  isPlatformAdmin: boolean
  subscribedAppIds: Set<string>
}): UserModuleAccessRow[] {
  const apps = sortApplicationsByCatalog(opts.applications.map(toApplication))
  const visible = filterAppsByOrgAccess(
    filterHubApplications(apps, {
      membershipRoles: opts.membershipRoles,
      fleetRole: opts.fleetRole,
    }),
    {
      isPlatformAdmin: opts.isPlatformAdmin,
      subscribedAppIds: opts.subscribedAppIds,
    },
  )
  const visibleIds = new Set(visible.map((a) => a.id))

  return apps.map((app) => {
    const slug = productAppSlug(app)
    const inferred = slug
      ? inferredReasonForSlug(slug, {
          membershipRoles: opts.membershipRoles,
          fleetRole: opts.fleetRole,
          isPlatformAdmin: opts.isPlatformAdmin,
        })
      : null
    const fromDashboard = visibleIds.has(app.id)
    const hasAccess = fromDashboard
    let reason = 'Brak dostępu'
    if (opts.isPlatformAdmin) reason = 'Administrator platformy'
    else if (fromDashboard && inferred) reason = inferred
    else if (fromDashboard && opts.subscribedAppIds.has(app.id)) reason = 'Subskrypcja firmy'
    else if (app.is_free && fromDashboard) reason = 'Moduł darmowy'
    else if (fromDashboard) reason = 'Dostęp z panelu logowania'
    return { id: app.id, name: app.name, hasAccess, reason }
  })
}

export async function fetchUserIdsWithModuleAccess(app: ProductAppOption): Promise<string[]> {
  const ids = new Set<string>()
  const slug = productAppSlug(app)

  let subscribedOrgIds: string[] = []
  const { data: subs, error: subsErr } = await supabase
    .from('org_subscriptions')
    .select('org_id, status, expires_at')
    .eq('app_id', app.id)
  if (subsErr) {
    console.error('[adminUserAccess] org_subscriptions:', subsErr)
  } else {
    subscribedOrgIds = (subs ?? [])
      .filter((row) => isSubscriptionCurrent(row.status, row.expires_at))
      .map((row) => row.org_id)
    if (subscribedOrgIds.length > 0) {
      const { data: mems, error: memErr } = await supabase
        .from('memberships')
        .select('user_id')
        .in('org_id', subscribedOrgIds)
      if (memErr) console.error('[adminUserAccess] memberships by org:', memErr)
      for (const m of mems ?? []) ids.add(m.user_id)
    }
  }

  const { data: admins, error: adminErr } = await supabase.from('profiles').select('id').eq('platform_role', 'admin')
  if (adminErr) console.error('[adminUserAccess] platform admins:', adminErr)
  else for (const p of admins ?? []) ids.add(p.id)

  if (slug === 'flota') {
    const { data: fleetProfiles, error: fleetErr } = await supabase
      .from('profiles')
      .select('id')
      .not('fleet_role', 'is', null)
    if (fleetErr) console.error('[adminUserAccess] fleet_role:', fleetErr)
    const fleetIds = new Set((fleetProfiles ?? []).map((row) => row.id))
    for (const id of [...ids]) {
      if (!fleetIds.has(id)) ids.delete(id)
    }
    if (subscribedOrgIds.length > 0) {
      const { data: vehicles, error: vehicleErr } = await supabase
        .from('vehicles')
        .select('assigned_driver_id')
        .in('org_id', subscribedOrgIds)
        .not('assigned_driver_id', 'is', null)
      if (vehicleErr) console.error('[adminUserAccess] fleet vehicles:', vehicleErr)
      for (const row of vehicles ?? []) {
        if (row.assigned_driver_id && fleetIds.has(row.assigned_driver_id)) {
          ids.add(row.assigned_driver_id)
        }
      }
    }
    for (const p of admins ?? []) ids.add(p.id)
  } else if (slug === 'home') {
    const { data, error } = await supabase
      .from('profiles')
      .select('id')
      .in('account_type', ['hub', 'standard'])
    if (error) console.error('[adminUserAccess] full accounts:', error)
    else for (const p of data ?? []) ids.add(p.id)
  } else {
    const roles =
      slug === 'cleaning'
        ? CLEANING_MEMBERSHIP_ROLES
        : slug === 'serwis'
          ? SERWIS_MEMBERSHIP_ROLES
          : slug === 'administracja'
            ? ADMINISTRACJA_MEMBERSHIP_ROLES
            : []
    if (roles.length > 0) {
      const { data, error } = await supabase.from('memberships').select('user_id').in('role', roles)
      if (error) console.error('[adminUserAccess] memberships by role:', error)
      else for (const m of data ?? []) ids.add(m.user_id)
    }
  }

  return [...ids]
}
