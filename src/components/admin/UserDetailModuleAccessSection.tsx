import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../../lib/supabase'
import { inputClass } from './pricingAdminUtils'
import type { MembershipWithOrg, ProfileDetailRow } from './usersAndOrgsTypes'
import { nestedName } from './usersAndOrgsUtils'

type ApplicationRow = {
  id: string
  name: string
  is_active: boolean | null
}

type OrgSubRow = {
  id: string
  app_id: string
  status: string
  expires_at: string | null
}

function defaultExpiresAtIso(): string {
  return new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
}

/** Local calendar date for input[type=date] (YYYY-MM-DD). */
function expiresAtToDateInputValue(iso: string | null): string {
  if (!iso) return ''
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ''
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

/** Noon local time to reduce timezone edge cases when persisting a picked calendar day. */
function dateInputToExpiresIso(ymd: string): string | null {
  const t = ymd.trim()
  if (!t) return null
  const d = new Date(`${t}T12:00:00`)
  if (Number.isNaN(d.getTime())) return null
  return d.toISOString()
}

const ROLE_OPTIONS: { value: string; label: string }[] = [
  { value: 'owner', label: 'Właściciel' },
  { value: 'coordinator', label: 'Administrator' },
  { value: 'cleaner', label: 'Pracownik' },
]

function isSubActive(status: string): boolean {
  return status.trim().toLowerCase() === 'active'
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
  const [moduleError, setModuleError] = useState<string | null>(null)
  const [togglingAppId, setTogglingAppId] = useState<string | null>(null)
  const [expirySavingAppId, setExpirySavingAppId] = useState<string | null>(null)

  const [applications, setApplications] = useState<ApplicationRow[]>([])
  const [subsByAppId, setSubsByAppId] = useState<Map<string, OrgSubRow>>(new Map())
  const [appsLoading, setAppsLoading] = useState(false)

  const primaryMembership = memberships[0] ?? null
  const primaryOrgId = primaryMembership?.org_id ?? null
  const primaryOrgName = primaryMembership ? nestedName(primaryMembership.organizations) : '—'

  const loadAppsAndSubs = useCallback(async () => {
    if (!primaryOrgId) {
      setApplications([])
      setSubsByAppId(new Map())
      return
    }
    setAppsLoading(true)
    setModuleError(null)
    try {
      const [appsRes, subsRes] = await Promise.all([
        supabase.from('applications').select('id,name,is_active').order('name'),
        supabase.from('org_subscriptions').select('id,app_id,status,expires_at').eq('org_id', primaryOrgId),
      ])
      if (appsRes.error) {
        console.error('[UserDetailModuleAccessSection] applications:', appsRes.error)
        setModuleError('Nie udało się pobrać listy modułów.')
        setApplications([])
      } else {
        const list = (appsRes.data ?? []) as ApplicationRow[]
        setApplications(list.filter((a) => a.is_active !== false))
      }
      if (subsRes.error) {
        console.error('[UserDetailModuleAccessSection] org_subscriptions:', subsRes.error)
        setModuleError((prev) => prev ?? 'Nie udało się pobrać subskrypcji organizacji.')
        setSubsByAppId(new Map())
      } else {
        const map = new Map<string, OrgSubRow>()
        for (const row of subsRes.data ?? []) {
          const r = row as OrgSubRow
          if (!map.has(r.app_id)) map.set(r.app_id, r)
        }
        setSubsByAppId(map)
      }
    } catch (e) {
      console.error('[UserDetailModuleAccessSection] loadAppsAndSubs:', e)
      setModuleError('Wystąpił błąd podczas ładowania modułów.')
    } finally {
      setAppsLoading(false)
    }
  }, [primaryOrgId])

  useEffect(() => {
    void loadAppsAndSubs()
  }, [loadAppsAndSubs])

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
    if (!primaryMembership) return
    setRoleError(null)
    setRoleBusy(true)
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

  const updateSubscriptionExpiry = async (sub: OrgSubRow, ymd: string) => {
    if (!isSubActive(sub.status)) return
    const trimmed = ymd.trim()
    const currentYmd = expiresAtToDateInputValue(sub.expires_at)
    if (trimmed === currentYmd) return
    setModuleError(null)
    setExpirySavingAppId(sub.app_id)
    const expires_at = dateInputToExpiresIso(ymd)
    try {
      const { data, error } = await supabase
        .from('org_subscriptions')
        .update({ expires_at })
        .eq('id', sub.id)
        .select('id,app_id,status,expires_at')
        .maybeSingle()
      if (error) {
        console.error('[UserDetailModuleAccessSection] expires_at update:', error)
        setModuleError(error.message || 'Nie udało się zaktualizować daty wygaśnięcia.')
        return
      }
      if (data) {
        const row = data as OrgSubRow
        setSubsByAppId((prev) => {
          const next = new Map(prev)
          next.set(row.app_id, row)
          return next
        })
      }
    } catch (e) {
      console.error('[UserDetailModuleAccessSection] updateSubscriptionExpiry:', e)
      setModuleError('Wystąpił błąd podczas zapisu daty.')
    } finally {
      setExpirySavingAppId(null)
    }
  }

  const setModuleActive = async (appId: string, appName: string, nextActive: boolean) => {
    if (!primaryOrgId) return
    setModuleError(null)
    setTogglingAppId(appId)
    const nextStatus = nextActive ? 'active' : 'inactive'
    const expiresOnActivate = defaultExpiresAtIso()
    try {
      const existing = subsByAppId.get(appId)
      if (existing) {
        const { data, error } = await supabase
          .from('org_subscriptions')
          .update({
            status: nextStatus,
            expires_at: nextActive ? expiresOnActivate : null,
          })
          .eq('id', existing.id)
          .select('id,app_id,status,expires_at')
          .maybeSingle()
        if (error) {
          console.error('[UserDetailModuleAccessSection] sub update:', error)
          setModuleError(error.message || 'Nie udało się zaktualizować modułu.')
          return
        }
        if (data) {
          const row = data as OrgSubRow
          setSubsByAppId((prev) => {
            const next = new Map(prev)
            next.set(appId, row)
            return next
          })
        }
        return
      }
      if (!nextActive) return
      const { data: inserted, error: insErr } = await supabase
        .from('org_subscriptions')
        .insert({
          org_id: primaryOrgId,
          app_id: appId,
          status: nextStatus,
          expires_at: expiresOnActivate,
        })
        .select('id,app_id,status,expires_at')
        .maybeSingle()
      if (insErr) {
        console.error('[UserDetailModuleAccessSection] sub insert:', insErr)
        setModuleError(insErr.message || `Nie udało się włączyć modułu „${appName}”.`)
        return
      }
      if (inserted) {
        const row = inserted as OrgSubRow
        setSubsByAppId((prev) => {
          const next = new Map(prev)
          next.set(appId, row)
          return next
        })
      }
    } catch (e) {
      console.error('[UserDetailModuleAccessSection] setModuleActive:', e)
      setModuleError('Wystąpił błąd podczas zmiany modułu.')
    } finally {
      setTogglingAppId(null)
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

  const envLabel = `Środowisko: ${profile.full_name?.trim() || 'Użytkownik'} - ${primaryOrgName}`

  return (
    <section className="bento-card p-6 space-y-4">
      <h2 className="font-display text-lg font-semibold">Dostęp do modułów i role</h2>

      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <p className="text-sm font-medium text-foreground">{envLabel}</p>
        <div className="flex flex-wrap items-center gap-2">
          <label htmlFor="primary-org-role" className="text-sm text-muted-foreground whitespace-nowrap">
            Rola w firmie
          </label>
          <select
            id="primary-org-role"
            disabled={roleBusy || !primaryMembership}
            className={`${inputClass} min-w-[12rem]`}
            value={
              ROLE_OPTIONS.some((o) => o.value === primaryMembership?.role)
                ? primaryMembership!.role
                : 'owner'
            }
            onChange={(e) => void updatePrimaryRole(e.target.value)}
          >
            {ROLE_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
          {roleBusy && <span className="text-xs text-muted-foreground">Zapisywanie…</span>}
        </div>
      </div>
      {roleError && (
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {roleError}
        </div>
      )}

      <div className="space-y-2">
        <h3 className="text-sm font-medium text-muted-foreground">Moduły platformy</h3>
        {moduleError && (
          <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
            {moduleError}
          </div>
        )}
        {appsLoading ? (
          <p className="text-sm text-muted-foreground">Ładowanie modułów…</p>
        ) : applications.length === 0 ? (
          <p className="text-sm text-muted-foreground">Brak zdefiniowanych modułów w systemie.</p>
        ) : (
          <ul className="divide-y divide-border/60 rounded-xl border border-border/60 overflow-hidden">
            {applications.map((app) => {
              const sub = subsByAppId.get(app.id)
              const active = sub ? isSubActive(sub.status) : false
              const busy = togglingAppId === app.id
              const expiryBusy = expirySavingAppId === app.id
              return (
                <li key={app.id} className="flex flex-wrap items-center justify-between gap-4 px-4 py-3 bg-background/50">
                  <div>
                    <p className="font-medium">{app.name?.trim() || '—'}</p>
                    <p className="text-xs text-muted-foreground">
                      {sub ? `Status: ${sub.status}` : 'Brak wpisu subskrypcji — włączenie utworzy rekord.'}
                    </p>
                  </div>
                  <div className="flex flex-wrap items-center gap-3 shrink-0">
                    {active && sub && (
                      <div className="flex flex-col gap-0.5">
                        <span className="text-[10px] uppercase tracking-wide text-muted-foreground">Wygasa</span>
                        <input
                          type="date"
                          disabled={busy || expiryBusy}
                          className={`${inputClass} w-[11rem] text-sm py-1.5 h-9`}
                          value={expiresAtToDateInputValue(sub.expires_at)}
                          onChange={(e) => void updateSubscriptionExpiry(sub, e.target.value)}
                        />
                      </div>
                    )}
                    <label className="flex items-center gap-3 cursor-pointer select-none">
                      <span className="text-sm text-muted-foreground">{active ? 'Włączony' : 'Wyłączony'}</span>
                      <input
                        type="checkbox"
                        disabled={busy}
                        className="h-4 w-4 rounded border-input text-primary focus:ring-ring disabled:opacity-50"
                        checked={active}
                        onChange={(e) => void setModuleActive(app.id, app.name, e.target.checked)}
                      />
                    </label>
                  </div>
                </li>
              )
            })}
          </ul>
        )}
      </div>

      {memberships.length > 1 && (
        <p className="text-xs text-muted-foreground">
          Użytkownik ma wiele przypisań do firm — powyżej zarządzasz pierwszą organizacją (najstarsze członkostwo).
          Pełna lista znajduje się w sekcji „Członkostwa w firmach”.
        </p>
      )}
    </section>
  )
}
