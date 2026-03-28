import { useCallback, useEffect, useState } from 'react'
import { ArrowLeft } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { inputClass } from './pricingAdminUtils'
import type { MembershipWithOrg, ProfileDetailRow, TaskExecutionLogRow } from './usersAndOrgsTypes'
import { formatDateOnly, formatDateTime, membershipRoleLabel, nestedName } from './usersAndOrgsUtils'

type Props = {
  userId: string
  onBack: () => void
}

export default function UserDetail({ userId, onBack }: Props) {
  const [profile, setProfile] = useState<ProfileDetailRow | null>(null)
  const [editForm, setEditForm] = useState({ full_name: '', phone: '' })
  const [memberships, setMemberships] = useState<MembershipWithOrg[]>([])
  const [logs, setLogs] = useState<TaskExecutionLogRow[] | null>(null)
  const [logsSkipped, setLogsSkipped] = useState(false)
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  const load = useCallback(async () => {
    setLoadError(null)
    setLoading(true)
    setLogsSkipped(false)
    try {
      const [profRes, memRes] = await Promise.all([
        supabase
          .from('profiles')
          .select(
            'id,full_name,email,phone,platform_role,accepted_terms_at,terms_version,marketing_consent,created_at,last_login_at',
          )
          .eq('id', userId)
          .maybeSingle(),
        supabase.from('memberships').select('*').eq('user_id', userId),
      ])

      if (profRes.error) {
        console.error('[UserDetail] profile:', profRes.error)
        setLoadError('Nie udało się pobrać profilu użytkownika.')
        setProfile(null)
        return
      }

      const row = profRes.data as ProfileDetailRow | null
      setProfile(row)
      if (row) {
        setEditForm({
          full_name: row.full_name?.trim() ?? '',
          phone: row.phone?.trim() ?? '',
        })
      }

      if (memRes.error) {
        console.error('[UserDetail] memberships:', memRes.error)
        setMemberships([])
      } else {
        const membershipsData = (memRes.data ?? []) as {
          id: string
          org_id: string
          role: string
        }[]
        const orgIds = [...new Set(membershipsData.map((m) => m.org_id))]
        const orgMap = new Map<string, { id: string; name: string }>()
        if (orgIds.length > 0) {
          const { data: orgsData, error: orgsErr } = await supabase
            .from('organizations')
            .select('id,name')
            .in('id', orgIds)
          if (orgsErr) {
            console.error('[UserDetail] organizations:', orgsErr)
          } else {
            for (const o of orgsData ?? []) {
              orgMap.set(o.id, o as { id: string; name: string })
            }
          }
        }
        const stitched: MembershipWithOrg[] = membershipsData.map((m) => {
          const org = orgMap.get(m.org_id)
          return {
            id: m.id,
            org_id: m.org_id,
            role: m.role,
            organizations: org ? { name: org.name } : null,
          }
        })
        setMemberships(stitched)
      }

      const logsRes = await supabase
        .from('task_execution_logs')
        .select('id,action_type,notes,created_at')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(10)

      if (logsRes.error) {
        console.error('[UserDetail] task_execution_logs:', logsRes.error)
        setLogs(null)
        setLogsSkipped(true)
      } else {
        setLogs((logsRes.data as TaskExecutionLogRow[]) ?? [])
        setLogsSkipped(false)
      }
    } catch (e) {
      console.error('[UserDetail] load:', e)
      setLoadError('Wystąpił błąd podczas ładowania.')
    } finally {
      setLoading(false)
    }
  }, [userId])

  useEffect(() => {
    void load()
  }, [load])

  const saveProfile = async () => {
    setSaveError(null)
    setSaving(true)
    try {
      const { error } = await supabase
        .from('profiles')
        .update({
          full_name: editForm.full_name.trim() || null,
          phone: editForm.phone.trim() || null,
        })
        .eq('id', userId)

      if (error) {
        console.error('[UserDetail] save:', error)
        setSaveError(error.message || 'Nie udało się zapisać zmian.')
        return
      }
      await load()
    } catch (e) {
      console.error('[UserDetail] save:', e)
      setSaveError('Wystąpił nieoczekiwany błąd podczas zapisu.')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="bento-card p-8 text-center text-muted-foreground">Ładowanie szczegółów użytkownika…</div>
    )
  }

  if (loadError || !profile) {
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
        <div className="bento-card p-6 text-destructive text-sm">{loadError ?? 'Nie znaleziono użytkownika.'}</div>
      </div>
    )
  }

  const showLogsPlaceholder = logsSkipped || !logs || logs.length === 0

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
            <label className="block text-sm text-muted-foreground" htmlFor="user-full-name">
              Imię i nazwisko
            </label>
            <input
              id="user-full-name"
              className={inputClass}
              value={editForm.full_name}
              onChange={(e) => setEditForm((f) => ({ ...f, full_name: e.target.value }))}
            />
          </div>
          <div className="space-y-1.5 sm:col-span-2">
            <label className="block text-sm text-muted-foreground" htmlFor="user-phone">
              Telefon
            </label>
            <input
              id="user-phone"
              className={inputClass}
              value={editForm.phone}
              onChange={(e) => setEditForm((f) => ({ ...f, phone: e.target.value }))}
            />
          </div>
        </div>
        <button
          type="button"
          disabled={saving}
          onClick={() => void saveProfile()}
          className="inline-flex items-center justify-center rounded-md bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50"
        >
          {saving ? 'Zapisywanie…' : 'Zapisz zmiany'}
        </button>
      </section>

      <section className="bento-card p-6 space-y-4">
        <h2 className="font-display text-lg font-semibold">Informacje systemowe</h2>
        <dl className="grid sm:grid-cols-2 gap-x-8 gap-y-3 text-sm">
          <div>
            <dt className="text-muted-foreground">E-mail</dt>
            <dd className="font-medium mt-0.5">{profile.email?.trim() ?? '—'}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Rola platformowa</dt>
            <dd className="font-medium mt-0.5">{profile.platform_role?.trim() ?? '—'}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Akceptacja regulaminu</dt>
            <dd className="font-medium mt-0.5">{formatDateTime(profile.accepted_terms_at)}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Wersja regulaminu</dt>
            <dd className="font-medium mt-0.5">{profile.terms_version?.trim() ?? '—'}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Zgoda marketingowa</dt>
            <dd className="font-medium mt-0.5">{profile.marketing_consent === true ? 'Tak' : 'Nie'}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Data utworzenia konta</dt>
            <dd className="font-medium mt-0.5">
              {profile.created_at ? formatDateTime(profile.created_at) : 'Brak danych'}
            </dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Ostatnie logowanie</dt>
            <dd className="font-medium mt-0.5">
              {profile.last_login_at ? formatDateTime(profile.last_login_at) : 'Brak danych'}
            </dd>
          </div>
        </dl>
      </section>

      <section className="bento-card p-6 space-y-4">
        <h2 className="font-display text-lg font-semibold">Członkostwa w firmach</h2>
        <div className="overflow-x-auto -mx-6 px-6 sm:mx-0 sm:px-0">
          <table className="w-full text-sm min-w-[24rem]">
            <thead>
              <tr className="border-b border-border/60 text-left text-muted-foreground">
                <th className="p-3 font-medium">Firma</th>
                <th className="p-3 font-medium">Rola</th>
              </tr>
            </thead>
            <tbody>
              {memberships.map((m) => (
                <tr key={m.id} className="border-b border-border/40 last:border-0">
                  <td className="p-3 font-medium">{nestedName(m.organizations)}</td>
                  <td className="p-3 text-muted-foreground">{membershipRoleLabel(m.role)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {memberships.length === 0 && (
            <p className="text-sm text-muted-foreground pt-2">Brak członkostw w organizacjach.</p>
          )}
        </div>
      </section>

      <section className="bento-card p-6 space-y-4">
        <h2 className="font-display text-lg font-semibold">Aktywność / logi</h2>
        {showLogsPlaceholder ? (
          <p className="text-sm text-muted-foreground">Brak ostatnich logów operacyjnych.</p>
        ) : (
          <div className="overflow-x-auto -mx-6 px-6 sm:mx-0 sm:px-0">
            <table className="w-full text-sm min-w-[28rem]">
              <thead>
                <tr className="border-b border-border/60 text-left text-muted-foreground">
                  <th className="p-3 font-medium">Data</th>
                  <th className="p-3 font-medium">Akcja</th>
                  <th className="p-3 font-medium">Notatka</th>
                </tr>
              </thead>
              <tbody>
                {logs!.map((log) => (
                  <tr key={log.id} className="border-b border-border/40 last:border-0">
                    <td className="p-3 text-muted-foreground whitespace-nowrap">{formatDateOnly(log.created_at)}</td>
                    <td className="p-3 font-medium">{log.action_type}</td>
                    <td className="p-3 text-muted-foreground">{log.notes?.trim() ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  )
}
