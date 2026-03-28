import { useCallback, useEffect, useState } from 'react'
import { ArrowLeft } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { inputClass } from './pricingAdminUtils'
import type { MembershipWithProfile, OrganizationDetailRow, OrgSubscriptionRow } from './usersAndOrgsTypes'
import { displayPersonName, formatDateTime, membershipRoleLabel, nestedName } from './usersAndOrgsUtils'

type Props = {
  organizationId: string
  onBack: () => void
}

export default function OrganizationDetail({ organizationId, onBack }: Props) {
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

  const load = useCallback(async () => {
    setLoadError(null)
    setLoading(true)
    try {
      const [orgRes, subRes, memRes] = await Promise.all([
        supabase
          .from('organizations')
          .select('id, name, nip, address, city, postal_code, created_at')
          .eq('id', organizationId)
          .maybeSingle(),
        supabase
          .from('org_subscriptions')
          .select('id, org_id, app_id, status, created_at, applications(name)')
          .eq('org_id', organizationId),
        supabase.from('memberships').select('id, role, user_id').eq('org_id', organizationId),
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
        setSubscriptions((subRes.data as unknown as OrgSubscriptionRow[]) ?? [])
      }

      if (memRes.error) {
        console.error('[OrganizationDetail] memberships:', memRes.error)
        setMemberships([])
      } else {
        const rows = (memRes.data as { id: string; role: string; user_id: string }[]) ?? []
        const userIds = [...new Set(rows.map((r) => r.user_id))]
        let profileMap = new Map<
          string,
          { first_name: string | null; last_name: string | null; full_name: string | null; email: string | null }
        >()
        if (userIds.length > 0) {
          const profRes = await supabase
            .from('profiles')
            .select('id, first_name, last_name, full_name, email')
            .in('id', userIds)
          if (profRes.error) {
            console.error('[OrganizationDetail] profiles for memberships:', profRes.error)
          } else {
            const plist = profRes.data as {
              id: string
              first_name: string | null
              last_name: string | null
              full_name: string | null
              email: string | null
            }[]
            profileMap = new Map(plist.map((p) => [p.id, p]))
          }
        }
        const merged: MembershipWithProfile[] = rows.map((r) => ({
          id: r.id,
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
                <th className="p-3 font-medium">Imię i nazwisko</th>
                <th className="p-3 font-medium">E-mail</th>
                <th className="p-3 font-medium">Rola</th>
              </tr>
            </thead>
            <tbody>
              {memberships.map((m) => (
                <tr key={m.id} className="border-b border-border/40 last:border-0">
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
