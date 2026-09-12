import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { Check, ChevronDown } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { isHubApplication, isSubscriptionCurrent } from '../../lib/moduleAccess'
import { computeUserModuleAccess, type ProductAppOption, type UserModuleAccessRow } from './adminUserAccess'
import type { MembershipWithOrg, ProfileDetailRow } from './usersAndOrgsTypes'
import {
  MEMBERSHIP_ROLE_OPTIONS,
  isSimplifiedAccount,
  membershipRoleLabel,
  nestedName,
} from './usersAndOrgsUtils'

type OrgSubRow = {
  app_id: string
  status: string
  expires_at: string | null
}

function rankMembershipRole(role: string): number {
  const order = [
    'owner',
    'wlasciciel',
    'admin',
    'administrator',
    'coordinator',
    'koordynator',
    'manager',
    'technik',
    'cleaner',
    'staff',
  ]
  const idx = order.indexOf(role.trim().toLowerCase())
  return idx === -1 ? 99 : idx
}

function pickPrimaryMembership(memberships: MembershipWithOrg[]): MembershipWithOrg | null {
  if (memberships.length === 0) return null
  return [...memberships].sort((a, b) => rankMembershipRole(a.role) - rankMembershipRole(b.role))[0]
}

type Props = {
  userId: string
  profile: ProfileDetailRow
  memberships: MembershipWithOrg[]
  onRefresh: () => Promise<void>
}

export default function UserDetailModuleAccessSection({
  userId,
  profile,
  memberships,
  onRefresh,
}: Props) {
  const [sandboxBusy, setSandboxBusy] = useState(false)
  const [sandboxError, setSandboxError] = useState<string | null>(null)
  const [roleBusy, setRoleBusy] = useState(false)
  const [roleError, setRoleError] = useState<string | null>(null)
  const [roleMenuOpen, setRoleMenuOpen] = useState(false)
  const roleMenuRef = useRef<HTMLDivElement | null>(null)

  const [moduleRows, setModuleRows] = useState<UserModuleAccessRow[]>([])
  const [appsLoading, setAppsLoading] = useState(false)
  const [moduleError, setModuleError] = useState<string | null>(null)

  const primaryMembership = pickPrimaryMembership(memberships)
  const primaryOrgName = primaryMembership ? nestedName(primaryMembership.organizations) : '—'

  const roleOptions = useMemo(() => {
    const current = (primaryMembership?.role ?? '').trim()
    if (!current) return MEMBERSHIP_ROLE_OPTIONS
    if (MEMBERSHIP_ROLE_OPTIONS.some((o) => o.value === current)) return MEMBERSHIP_ROLE_OPTIONS
    return [{ value: current, label: membershipRoleLabel(current) }, ...MEMBERSHIP_ROLE_OPTIONS]
  }, [primaryMembership?.role])

  const currentRoleValue = primaryMembership?.role ?? ''

  useEffect(() => {
    if (!roleMenuOpen) return
    const onDocClick = (event: MouseEvent) => {
      if (roleMenuRef.current && !roleMenuRef.current.contains(event.target as Node)) {
        setRoleMenuOpen(false)
      }
    }
    document.addEventListener('mousedown', onDocClick)
    return () => document.removeEventListener('mousedown', onDocClick)
  }, [roleMenuOpen])

  const loadModuleAccess = useCallback(async () => {
    setAppsLoading(true)
    setModuleError(null)
    try {
      const orgIds = [...new Set(memberships.map((m) => m.org_id))]
      const [appsRes, subsRes] = await Promise.all([
        supabase.from('applications').select('id,name,is_active,is_free,domain_url,api_url').eq('is_active', true),
        orgIds.length > 0
          ? supabase.from('org_subscriptions').select('app_id,status,expires_at').in('org_id', orgIds)
          : Promise.resolve({ data: [] as OrgSubRow[], error: null }),
      ])
      if (appsRes.error) {
        console.error('[UserDetailModuleAccessSection] applications:', appsRes.error)
        setModuleError('Nie udało się pobrać listy modułów.')
        setModuleRows([])
        return
      }
      if (subsRes.error) {
        console.error('[UserDetailModuleAccessSection] org_subscriptions:', subsRes.error)
      }
      const productApps = ((appsRes.data ?? []) as ProductAppOption[]).filter(
        (app) =>
          !isHubApplication({
            name: app.name,
            domain_url: app.domain_url ?? '',
            api_url: app.api_url,
          }),
      )
      const subscribedAppIds = new Set(
        ((subsRes.data ?? []) as OrgSubRow[])
          .filter((row) => isSubscriptionCurrent(row.status, row.expires_at))
          .map((row) => row.app_id),
      )
      setModuleRows(
        computeUserModuleAccess({
          applications: productApps,
          membershipRoles: memberships.map((m) => m.role),
          fleetRole: profile.fleet_role,
          isPlatformAdmin: (profile.platform_role ?? '').trim().toLowerCase() === 'admin',
          subscribedAppIds,
        }),
      )
    } catch (e) {
      console.error('[UserDetailModuleAccessSection] loadModuleAccess:', e)
      setModuleError('Wystąpił błąd podczas ładowania dostępu do modułów.')
    } finally {
      setAppsLoading(false)
    }
  }, [memberships, profile.fleet_role, profile.platform_role])

  useEffect(() => {
    void loadModuleAccess()
  }, [loadModuleAccess])

  const createSandbox = async () => {
    setSandboxError(null)
    setSandboxBusy(true)
    try {
      const displayName = profile.full_name?.trim() || 'Użytkownik'
      const orgName = `Piaskownica - ${displayName}`
      const baseSlug = `sandbox-${userId.replace(/-/g, '')}`
      let slug = baseSlug
      let attempt = 0
      while (attempt < 5) {
        const { data: inserted, error: insErr } = await supabase
          .from('organizations')
          .insert({ name: orgName, slug })
          .select('id')
          .maybeSingle()
        if (!insErr && inserted?.id) {
          const orgId = inserted.id as string
          const { error: memErr } = await supabase.from('memberships').insert({
            user_id: userId,
            org_id: orgId,
            role: 'owner',
          })
          if (memErr) {
            console.error('[UserDetailModuleAccessSection] memberships insert:', memErr)
            setSandboxError(memErr.message || 'Nie udało się przypisać użytkownika do firmy.')
            return
          }
          await onRefresh()
          return
        }
        if (insErr?.code === '23505' || insErr?.message?.toLowerCase().includes('unique')) {
          attempt += 1
          slug = `${baseSlug}-${attempt}`
          continue
        }
        console.error('[UserDetailModuleAccessSection] organizations insert:', insErr)
        setSandboxError(insErr?.message || 'Nie udało się utworzyć przestrzeni testowej.')
        return
      }
      setSandboxError('Nie udało się wygenerować unikalnego identyfikatora firmy.')
    } catch (e) {
      console.error('[UserDetailModuleAccessSection] createSandbox:', e)
      setSandboxError('Wystąpił nieoczekiwany błąd.')
    } finally {
      setSandboxBusy(false)
    }
  }

  const updatePrimaryRole = async (nextRole: string) => {
    if (!primaryMembership || nextRole === primaryMembership.role) {
      setRoleMenuOpen(false)
      return
    }
    setRoleError(null)
    setRoleBusy(true)
    setRoleMenuOpen(false)
    try {
      const { error } = await supabase.from('memberships').update({ role: nextRole }).eq('id', primaryMembership.id)
      if (error) {
        console.error('[UserDetailModuleAccessSection] role update:', error)
        setRoleError(error.message || 'Nie udało się zmienić roli.')
        return
      }
      await onRefresh()
    } catch (e) {
      console.error('[UserDetailModuleAccessSection] updatePrimaryRole:', e)
      setRoleError('Wystąpił błąd podczas zmiany roli.')
    } finally {
      setRoleBusy(false)
    }
  }

  if (memberships.length === 0) {
    return (
      <section className="bento-card p-6 space-y-4">
        <h2 className="font-display text-lg font-semibold">Dostęp do modułów i role</h2>
        <p className="text-sm text-muted-foreground max-w-xl">
          Ten użytkownik nie jest przypisany do żadnej firmy, przez co nie może korzystać z modułów platformy.
        </p>
        {sandboxError && (
          <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
            {sandboxError}
          </div>
        )}
        <div>
          <button
            type="button"
            disabled={sandboxBusy}
            onClick={() => void createSandbox()}
            className="inline-flex items-center justify-center rounded-xl bg-primary px-6 py-3 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50 min-w-[280px]"
          >
            {sandboxBusy ? 'Tworzenie…' : 'Utwórz przestrzeń testową (Sandbox)'}
          </button>
        </div>
      </section>
    )
  }

  return (
    <section className="bento-card p-6 space-y-6">
      <h2 className="font-display text-lg font-semibold">Dostęp do modułów i role</h2>

      <div className="space-y-2">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div>
            <p className="text-sm font-medium">Rola w firmie</p>
            <p className="text-xs text-muted-foreground">
              {isSimplifiedAccount(profile.account_type)
                ? 'Konto uproszczone — to nie jest konto właściciela platformy.'
                : `Firma: ${primaryOrgName}`}
            </p>
          </div>
          <div className="relative" ref={roleMenuRef}>
            <button
              type="button"
              disabled={roleBusy || !primaryMembership}
              onClick={() => setRoleMenuOpen((open) => !open)}
              className="inline-flex min-w-[16rem] items-center justify-between gap-2 rounded-md border border-input bg-background px-3 py-2 text-sm disabled:opacity-50"
              aria-haspopup="listbox"
              aria-expanded={roleMenuOpen}
            >
              <span>{currentRoleValue ? membershipRoleLabel(currentRoleValue) : 'Wybierz rolę'}</span>
              <ChevronDown className="h-4 w-4 text-muted-foreground" />
            </button>
            {roleMenuOpen && (
              <ul
                role="listbox"
                className="absolute right-0 z-20 mt-1 min-w-[16rem] overflow-hidden rounded-xl border border-border/70 bg-background shadow-lg"
              >
                {roleOptions.map((option) => {
                  const selected = option.value === currentRoleValue
                  return (
                    <li key={option.value}>
                      <button
                        type="button"
                        role="option"
                        aria-selected={selected}
                        className={`flex w-full items-center gap-2 px-3 py-2 text-left text-sm hover:bg-muted ${
                          selected ? 'font-medium text-primary' : ''
                        }`}
                        onClick={() => void updatePrimaryRole(option.value)}
                      >
                        <Check className={`h-4 w-4 ${selected ? 'opacity-100' : 'opacity-0'}`} aria-hidden />
                        {option.label}
                      </button>
                    </li>
                  )
                })}
              </ul>
            )}
          </div>
        </div>
        {roleBusy && <p className="text-xs text-muted-foreground">Zapisywanie roli…</p>}
        {roleError && (
          <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
            {roleError}
          </div>
        )}
      </div>

      <div className="space-y-2">
        <h3 className="text-sm font-medium">Moduły tego konta</h3>
        <p className="text-xs text-muted-foreground max-w-2xl">
          Lista pokazuje, do których aplikacji ten użytkownik ma wejście (typ konta, rola w firmie, subskrypcja
          organizacji). Włączanie pakietów dla całej firmy jest w karcie firmy — nie tutaj.
        </p>
        {moduleError && (
          <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
            {moduleError}
          </div>
        )}
        {appsLoading ? (
          <p className="text-sm text-muted-foreground">Ładowanie modułów…</p>
        ) : moduleRows.length === 0 ? (
          <p className="text-sm text-muted-foreground">Brak zdefiniowanych modułów w systemie.</p>
        ) : (
          <ul className="divide-y divide-border/60 rounded-xl border border-border/60 overflow-hidden">
            {moduleRows.map((row) => (
              <li key={row.id} className="flex items-center justify-between gap-4 px-4 py-3 bg-background/50">
                <div className="flex items-center gap-3 min-w-0">
                  <span
                    className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-full ${
                      row.hasAccess ? 'bg-primary/15 text-primary' : 'bg-muted text-muted-foreground'
                    }`}
                    aria-hidden
                  >
                    {row.hasAccess ? <Check className="h-3.5 w-3.5" /> : null}
                  </span>
                  <div className="min-w-0">
                    <p className="font-medium truncate">{row.name}</p>
                    <p className="text-xs text-muted-foreground">{row.reason}</p>
                  </div>
                </div>
                <span className="text-xs text-muted-foreground shrink-0">
                  {row.hasAccess ? 'Dostęp' : 'Brak'}
                </span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </section>
  )
}
