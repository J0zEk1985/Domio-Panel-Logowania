import { useCallback, useEffect, useMemo, useState } from 'react'
import { ArrowDown, ArrowLeft, ArrowUp } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { inputClass } from './pricingAdminUtils'
import type { MembershipWithProfile, OrganizationDetailRow, OrgSubscriptionRow } from './usersAndOrgsTypes'
import { displayPersonName, formatDateTime, membershipRoleLabel, nestedName } from './usersAndOrgsUtils'

export type OrganizationDetailProps = {
  organizationId: string
  onBack: () => void
  onUserClick?: (userId: string) => void
}

type MemberSortKey = 'role' | 'first_name' | 'last_name' | 'full_name' | 'email'
type MemberSortConfig = { key: MemberSortKey; direction: 'asc' | 'desc' }

function MemberSortableTh({
  label,
  sortKey,
  currentSort,
  onSort,
}: {
  label: string
  sortKey: MemberSortKey
  currentSort: MemberSortConfig
  onSort: (k: MemberSortKey) => void
}) {
  const active = currentSort.key === sortKey
  return (
    <th className="p-3 font-medium">
      <button
        type="button"
        className="inline-flex items-center gap-1.5 text-left hover:text-foreground text-muted-foreground hover:text-foreground"
        onClick={() => onSort(sortKey)}
      >
        {label}
        {active &&
          (currentSort.direction === 'asc' ? (
            <ArrowUp className="h-3.5 w-3.5 shrink-0 text-primary" aria-hidden />
          ) : (
            <ArrowDown className="h-3.5 w-3.5 shrink-0 text-primary" aria-hidden />
          ))}
      </button>
    </th>
  )
}

function strNorm(s: string | null | undefined): string {
  return (s ?? '').trim().toLowerCase()
}

function compareMembers(
  a: MembershipWithProfile,
  b: MembershipWithProfile,
  key: MemberSortKey,
  direction: 'asc' | 'desc',
): number {
  const dir = direction === 'asc' ? 1 : -1
  const pa = a.profiles
  const pb = b.profiles
  let cmp = 0
  switch (key) {
    case 'role':
      cmp = membershipRoleLabel(a.role).localeCompare(membershipRoleLabel(b.role), 'pl')
      break
    case 'email':
      cmp = strNorm(pa?.email).localeCompare(strNorm(pb?.email), 'pl', { sensitivity: 'base' })
      break
    case 'first_name':
      cmp = strNorm(pa?.first_name).localeCompare(strNorm(pb?.first_name), 'pl', { sensitivity: 'base' })
      if (cmp === 0) cmp = strNorm(pa?.last_name).localeCompare(strNorm(pb?.last_name), 'pl', { sensitivity: 'base' })
      break
    case 'last_name':
      cmp = strNorm(pa?.last_name).localeCompare(strNorm(pb?.last_name), 'pl', { sensitivity: 'base' })
      if (cmp === 0) cmp = strNorm(pa?.first_name).localeCompare(strNorm(pb?.first_name), 'pl', { sensitivity: 'base' })
      break
    case 'full_name':
      cmp = strNorm(pa?.full_name).localeCompare(strNorm(pb?.full_name), 'pl', { sensitivity: 'base' })
      break
    default:
      cmp = 0
  }
  return cmp * dir
}

export default function OrganizationDetail({ organizationId, onBack, onUserClick }: OrganizationDetailProps) {
  const [org, setOrg] = useState<OrganizationDetailRow | null>(null)
  const [name, setName] = useState('')
  const [nip, setNip] = useState('')
  const [address, setAddress] = useState('')
  const [city, setCity] = useState('')
  const [postalCode, setPostalCode] = useState('')
  const [subscriptions, setSubscriptions] = useState<OrgSubscriptionRow[]>([])
  const [memberships, setMemberships] = useState<MembershipWithProfile[]>([])
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [subToggleError, setSubToggleError] = useState<string | null>(null)
  const [memberSort, setMemberSort] = useState<MemberSortConfig>({ key: 'role', direction: 'asc' })

  const handleMemberSort = useCallback((key: MemberSortKey) => {
    setMemberSort((prev) =>
      prev.key === key
        ? { key, direction: prev.direction === 'asc' ? 'desc' : 'asc' }
        : { key, direction: 'asc' },
    )
  }, [])

  const sortedMembers = useMemo(() => {
    const list = [...memberships]
    list.sort((a, b) => compareMembers(a, b, memberSort.key, memberSort.direction))
    return list
  }, [memberships, memberSort])

  const load = useCallback(async () => {
    setLoadError(null)
    setLoading(true)
    try {
      const [orgRes, subRes, memRes] = await Promise.all([
        supabase
          .from('organizations')
          .select('id,name,nip,address,city,postal_code,created_at')
          .eq('id', organizationId)
          .maybeSingle(),
        supabase.from('org_subscriptions').select('*').eq('org_id', organizationId),
        supabase.from('memberships').select('*').eq('org_id', organizationId),
      ])

      if (orgRes.error) {
        console.error('[OrganizationDetail] org:', orgRes.error)
        setLoadError('Nie udało się pobrać danych firmy.')
        setOrg(null)
        return
      }
      const row = orgRes.data as OrganizationDetailRow | null
      setOrg(row)
      if (row) {
        setName(row.name ?? '')
        setNip(row.nip ?? '')
        setAddress(row.address ?? '')
        setCity(row.city ?? '')
        setPostalCode(row.postal_code ?? '')
      }

      if (subRes.error) {
        console.error('[OrganizationDetail] subscriptions:', subRes.error)
        setSubscriptions([])
      } else {
        type SubRow = {
          id: string
          org_id: string
          app_id: string
          status: string
          created_at: string | null
        }
        const subsData = (subRes.data ?? []) as SubRow[]
        const appIds = [...new Set(subsData.map((s) => s.app_id))]
        const appMap = new Map<string, { id: string; name: string }>()
        if (appIds.length > 0) {
          const { data: appsData, error: appsErr } = await supabase
            .from('applications')
            .select('id,name')
            .in('id', appIds)
          if (appsErr) {
            console.error('[OrganizationDetail] applications:', appsErr)
          } else {
            for (const a of appsData ?? []) {
              const row = a as { id: string; name: string }
              appMap.set(row.id, row)
            }
          }
        }
        const stitchedSubs: OrgSubscriptionRow[] = subsData.map((s) => {
          const app = appMap.get(s.app_id)
          return {
            ...s,
            applications: app ? { name: app.name } : null,
          }
        })
        setSubscriptions(stitchedSubs)
      }

      if (memRes.error) {
        console.error('[OrganizationDetail] memberships:', memRes.error)
        setMemberships([])
      } else {
        const membershipsData = (memRes.data ?? []) as {
          id: string
          user_id: string
          role: string
        }[]
        const userIds = [...new Set(membershipsData.map((m) => m.user_id))]
        const profileMap = new Map<
          string,
          {
            first_name: string | null
            last_name: string | null
            email: string | null
            full_name: string | null
          }
        >()
        if (userIds.length > 0) {
          const { data: profilesData, error: profErr } = await supabase
            .from('profiles')
            .select('id,first_name,last_name,email,full_name')
            .in('id', userIds)
          if (profErr) {
            console.error('[OrganizationDetail] profiles:', profErr)
          } else {
            for (const p of profilesData ?? []) {
              const row = p as {
                id: string
                first_name: string | null
                last_name: string | null
                email: string | null
                full_name: string | null
              }
              profileMap.set(row.id, {
                first_name: row.first_name,
                last_name: row.last_name,
                email: row.email,
                full_name: row.full_name,
              })
            }
          }
        }
        const merged: MembershipWithProfile[] = membershipsData.map((r) => ({
          id: r.id,
          user_id: r.user_id,
          role: r.role,
          profiles: profileMap.get(r.user_id) ?? null,
        }))
        setMemberships(merged)
      }
    } catch (e) {
      console.error('[OrganizationDetail] load:', e)
      setLoadError('Wystąpił błąd podczas ładowania.')
    } finally {
      setLoading(false)
    }
  }, [organizationId])

  useEffect(() => {
    void load()
  }, [load])

  const saveOrg = async () => {
    setSaveError(null)
    const trimmed = name.trim()
    if (!trimmed) {
      setSaveError('Nazwa firmy jest wymagana.')
      return
    }
    setSaving(true)
    try {
      const { error } = await supabase
        .from('organizations')
        .update({
          name: trimmed,
          nip: nip.trim() || null,
          address: address.trim() || null,
          city: city.trim() || null,
          postal_code: postalCode.trim() || null,
        })
        .eq('id', organizationId)

      if (error) {
        console.error('[OrganizationDetail] save:', error)
        setSaveError(error.message || 'Nie udało się zapisać zmian.')
        return
      }
      await load()
    } catch (e) {
      console.error('[OrganizationDetail] save:', e)
      setSaveError('Wystąpił nieoczekiwany błąd podczas zapisu.')
    } finally {
      setSaving(false)
    }
  }

  const toggleSubscriptionStatus = async (sub: OrgSubscriptionRow, nextActive: boolean) => {
    setSubToggleError(null)
    const nextStatus = nextActive ? 'active' : 'inactive'
    try {
      const { error } = await supabase
        .from('org_subscriptions')
        .update({ status: nextStatus })
        .eq('id', sub.id)

      if (error) {
        console.error('[OrganizationDetail] toggle sub:', error)
        setSubToggleError('Nie udało się zaktualizować statusu subskrypcji.')
        return
      }
      setSubscriptions((prev) =>
        prev.map((s) => (s.id === sub.id ? { ...s, status: nextStatus } : s)),
      )
    } catch (e) {
      console.error('[OrganizationDetail] toggle sub:', e)
      setSubToggleError('Wystąpił błąd podczas zmiany statusu.')
    }
  }

  const isSubActive = (status: string) => status.trim().toLowerCase() === 'active'

  if (loading) {
    return (
      <div className="bento-card p-8 text-center text-muted-foreground">Ładowanie szczegółów firmy…</div>
    )
  }

  if (loadError || !org) {
    return (
      <div className="space-y-4">
        <button
          type="button"
          onClick={onBack}
          className="inline-flex items-center gap-2 text-sm font-medium text-primary hover:underline"
        >
          <ArrowLeft className="h-4 w-4" />
          Wróć do listy
        </button>
        <div className="bento-card p-6 text-destructive text-sm">{loadError ?? 'Nie znaleziono firmy.'}</div>
      </div>
    )
  }

  return (
    <div className="space-y-8">
      <button
        type="button"
        onClick={onBack}
        className="inline-flex items-center gap-2 text-sm font-medium text-primary hover:underline"
      >
        <ArrowLeft className="h-4 w-4" />
        Wróć do listy
      </button>

      <section className="bento-card p-6 space-y-4">
        <h2 className="font-display text-lg font-semibold">Dane podstawowe</h2>
        {saveError && (
          <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
            {saveError}
          </div>
        )}
        <div className="grid sm:grid-cols-2 gap-4">
          <div className="space-y-1.5 sm:col-span-2">
            <label className="block text-sm text-muted-foreground" htmlFor="org-name">
              Nazwa
            </label>
            <input id="org-name" className={inputClass} value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="space-y-1.5">
            <label className="block text-sm text-muted-foreground" htmlFor="org-nip">
              NIP
            </label>
            <input id="org-nip" className={inputClass} value={nip} onChange={(e) => setNip(e.target.value)} />
          </div>
          <div className="space-y-1.5">
            <label className="block text-sm text-muted-foreground" htmlFor="org-city">
              Miasto
            </label>
            <input id="org-city" className={inputClass} value={city} onChange={(e) => setCity(e.target.value)} />
          </div>
          <div className="space-y-1.5 sm:col-span-2">
            <label className="block text-sm text-muted-foreground" htmlFor="org-address">
              Adres
            </label>
            <input id="org-address" className={inputClass} value={address} onChange={(e) => setAddress(e.target.value)} />
          </div>
          <div className="space-y-1.5">
            <label className="block text-sm text-muted-foreground" htmlFor="org-postal">
              Kod pocztowy
            </label>
            <input
              id="org-postal"
              className={inputClass}
              value={postalCode}
              onChange={(e) => setPostalCode(e.target.value)}
            />
          </div>
        </div>
        <button
          type="button"
          disabled={saving}
          onClick={() => void saveOrg()}
          className="inline-flex items-center justify-center rounded-md bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50"
        >
          {saving ? 'Zapisywanie…' : 'Zapisz zmiany'}
        </button>
      </section>

      <section className="bento-card p-6 space-y-4">
        <h2 className="font-display text-lg font-semibold">Subskrypcje modułów</h2>
        {subToggleError && (
          <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
            {subToggleError}
          </div>
        )}
        {subscriptions.length === 0 ? (
          <p className="text-sm text-muted-foreground">Brak przypisanych subskrypcji.</p>
        ) : (
          <ul className="divide-y divide-border/60 rounded-xl border border-border/60 overflow-hidden">
            {subscriptions.map((sub) => {
              const appName = nestedName(sub.applications)
              const active = isSubActive(sub.status)
              return (
                <li key={sub.id} className="flex flex-wrap items-center justify-between gap-4 px-4 py-3 bg-background/50">
                  <div>
                    <p className="font-medium">{appName}</p>
                    <p className="text-xs text-muted-foreground">
                      Status w bazie: {sub.status} · od {formatDateTime(sub.created_at)}
                    </p>
                  </div>
                  <label className="flex items-center gap-3 cursor-pointer select-none shrink-0">
                    <span className="text-sm text-muted-foreground">{active ? 'Aktywna' : 'Nieaktywna'}</span>
                    <input
                      type="checkbox"
                      className="h-4 w-4 rounded border-input text-primary focus:ring-ring"
                      checked={active}
                      onChange={(e) => void toggleSubscriptionStatus(sub, e.target.checked)}
                    />
                  </label>
                </li>
              )
            })}
          </ul>
        )}
      </section>

      <section className="bento-card p-6 space-y-4">
        <h2 className="font-display text-lg font-semibold">Pracownicy i członkowie</h2>
        <div className="overflow-x-auto -mx-6 px-6 sm:mx-0 sm:px-0">
          <table className="w-full text-sm min-w-[32rem]">
            <thead>
              <tr className="border-b border-border/60 text-left text-muted-foreground">
                <MemberSortableTh
                  label="Imię i nazwisko"
                  sortKey="last_name"
                  currentSort={memberSort}
                  onSort={handleMemberSort}
                />
                <MemberSortableTh
                  label="E-mail"
                  sortKey="email"
                  currentSort={memberSort}
                  onSort={handleMemberSort}
                />
                <MemberSortableTh
                  label="Rola"
                  sortKey="role"
                  currentSort={memberSort}
                  onSort={handleMemberSort}
                />
              </tr>
            </thead>
            <tbody>
              {sortedMembers.map((m) => (
                <tr
                  key={m.id}
                  className={`border-b border-border/40 last:border-0 transition-colors ${
                    onUserClick ? 'cursor-pointer hover:bg-muted/50' : ''
                  }`}
                  onClick={() => onUserClick?.(m.user_id)}
                >
                  <td className="p-3 font-medium">{displayPersonName(m.profiles ?? {})}</td>
                  <td className="p-3 text-muted-foreground">{m.profiles?.email?.trim() ?? '—'}</td>
                  <td className="p-3 text-muted-foreground">{membershipRoleLabel(m.role)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {memberships.length === 0 && (
            <p className="text-sm text-muted-foreground pt-2">Brak członków przypisanych do tej firmy.</p>
          )}
        </div>
      </section>
    </div>
  )
}
