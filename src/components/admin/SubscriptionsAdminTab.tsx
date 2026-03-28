import { useCallback, useEffect, useMemo, useState } from 'react'
import { Building2, CreditCard, Layers } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { inputClass } from './pricingAdminUtils'
import { formatDateOnly } from './usersAndOrgsUtils'

type OrgSubscriptionRaw = {
  id: string
  org_id: string
  app_id: string
  status: string
  created_at: string | null
}

export type GlobalSubscriptionRow = OrgSubscriptionRaw & {
  organizations: { name: string } | null
  applications: { name: string } | null
}

function isActiveStatus(status: string): boolean {
  return status.trim().toLowerCase() === 'active'
}

function StatusBadge({ active }: { active: boolean }) {
  return (
    <span
      className={
        active
          ? 'inline-flex items-center rounded-full bg-emerald-500/15 text-emerald-700 dark:text-emerald-400 border border-emerald-500/30 px-2.5 py-0.5 text-xs font-medium'
          : 'inline-flex items-center rounded-full bg-muted text-muted-foreground border border-border px-2.5 py-0.5 text-xs font-medium'
      }
    >
      {active ? 'Aktywny' : 'Nieaktywny'}
    </span>
  )
}

type StatusFilter = 'all' | 'active'

export default function SubscriptionsAdminTab() {
  const [rows, setRows] = useState<GlobalSubscriptionRow[]>([])
  const [loadError, setLoadError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')

  const load = useCallback(async () => {
    setLoadError(null)
    setLoading(true)
    try {
      const { data: subsData, error: subsErr } = await supabase.from('org_subscriptions').select('*')
      if (subsErr) {
        console.error('[SubscriptionsAdminTab] org_subscriptions:', subsErr)
        setLoadError('Nie udało się pobrać subskrypcji.')
        setRows([])
        return
      }
      const subs = (subsData ?? []) as OrgSubscriptionRaw[]
      const orgIds = [...new Set(subs.map((s) => s.org_id))]
      const appIds = [...new Set(subs.map((s) => s.app_id))]
      const orgMap = new Map<string, { id: string; name: string }>()
      const appMap = new Map<string, { id: string; name: string }>()

      if (orgIds.length > 0) {
        const { data: orgsData, error: orgsErr } = await supabase
          .from('organizations')
          .select('id,name')
          .in('id', orgIds)
        if (orgsErr) {
          console.error('[SubscriptionsAdminTab] organizations:', orgsErr)
        } else {
          for (const o of orgsData ?? []) {
            const row = o as { id: string; name: string }
            orgMap.set(row.id, row)
          }
        }
      }
      if (appIds.length > 0) {
        const { data: appsData, error: appsErr } = await supabase
          .from('applications')
          .select('id,name')
          .in('id', appIds)
        if (appsErr) {
          console.error('[SubscriptionsAdminTab] applications:', appsErr)
        } else {
          for (const a of appsData ?? []) {
            const row = a as { id: string; name: string }
            appMap.set(row.id, row)
          }
        }
      }

      const stitched: GlobalSubscriptionRow[] = subs.map((s) => {
        const org = orgMap.get(s.org_id)
        const app = appMap.get(s.app_id)
        return {
          ...s,
          organizations: org ? { name: org.name } : null,
          applications: app ? { name: app.name } : null,
        }
      })
      setRows(stitched)
    } catch (e) {
      console.error('[SubscriptionsAdminTab] load:', e)
      setLoadError('Wystąpił błąd podczas ładowania.')
      setRows([])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const metrics = useMemo(() => {
    const total = rows.length
    const activeModules = rows.filter((r) => isActiveStatus(r.status)).length
    const orgsWithSubs = new Set(rows.map((r) => r.org_id)).size
    return { total, activeModules, orgsWithSubs }
  }, [rows])

  const filteredRows = useMemo(() => {
    const q = search.trim().toLowerCase()
    return rows.filter((r) => {
      const orgName = (r.organizations?.name ?? '').toLowerCase()
      if (q && !orgName.includes(q)) return false
      if (statusFilter === 'active' && !isActiveStatus(r.status)) return false
      return true
    })
  }, [rows, search, statusFilter])

  return (
    <div className="space-y-8">
      <div>
        <h2 className="font-display text-xl font-semibold mb-1">Globalne subskrypcje</h2>
        <p className="text-muted-foreground text-sm">
          Przegląd wszystkich przypisań modułów do organizacji na platformie.
        </p>
      </div>

      {loadError && (
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {loadError}
        </div>
      )}

      <div className="grid sm:grid-cols-3 gap-4">
        <div className="bento-card">
          <div className="flex items-center justify-between mb-3">
            <div className="p-2.5 rounded-xl bg-muted">
              <CreditCard className="h-5 w-5 text-primary" />
            </div>
          </div>
          <p className="text-sm text-muted-foreground mb-1">Wszystkie subskrypcje</p>
          <p className="font-display text-2xl font-bold">{loading ? '…' : metrics.total.toLocaleString('pl-PL')}</p>
        </div>
        <div className="bento-card">
          <div className="flex items-center justify-between mb-3">
            <div className="p-2.5 rounded-xl bg-muted">
              <Layers className="h-5 w-5 text-primary" />
            </div>
          </div>
          <p className="text-sm text-muted-foreground mb-1">Aktywne moduły</p>
          <p className="font-display text-2xl font-bold">{loading ? '…' : metrics.activeModules.toLocaleString('pl-PL')}</p>
        </div>
        <div className="bento-card">
          <div className="flex items-center justify-between mb-3">
            <div className="p-2.5 rounded-xl bg-muted">
              <Building2 className="h-5 w-5 text-primary" />
            </div>
          </div>
          <p className="text-sm text-muted-foreground mb-1">Firmy z subskrypcjami</p>
          <p className="font-display text-2xl font-bold">{loading ? '…' : metrics.orgsWithSubs.toLocaleString('pl-PL')}</p>
        </div>
      </div>

      <div className="flex flex-col sm:flex-row gap-4 sm:items-end">
        <div className="flex-1 space-y-1.5">
          <label className="block text-sm text-muted-foreground" htmlFor="sub-search">
            Szukaj po nazwie firmy
          </label>
          <input
            id="sub-search"
            className={inputClass}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Wpisz fragment nazwy…"
          />
        </div>
        <div className="space-y-1.5 sm:w-56">
          <label className="block text-sm text-muted-foreground" htmlFor="sub-status">
            Status
          </label>
          <select
            id="sub-status"
            className={inputClass}
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as StatusFilter)}
          >
            <option value="all">Wszystkie</option>
            <option value="active">Tylko aktywne</option>
          </select>
        </div>
      </div>

      <div className="bento-card overflow-x-auto p-0 sm:p-0">
        <table className="w-full text-sm min-w-[42rem]">
          <thead>
            <tr className="border-b border-border/60 text-left text-muted-foreground">
              <th className="p-4 font-medium">Firma</th>
              <th className="p-4 font-medium">Moduł (aplikacja)</th>
              <th className="p-4 font-medium">Status</th>
              <th className="p-4 font-medium">Data aktywacji</th>
              <th className="p-4 font-medium">Data wygaśnięcia</th>
            </tr>
          </thead>
          <tbody>
            {!loading &&
              filteredRows.map((r) => (
                <tr key={r.id} className="border-b border-border/40 last:border-0">
                  <td className="p-4 font-medium">{r.organizations?.name?.trim() ?? '—'}</td>
                  <td className="p-4 text-muted-foreground">{r.applications?.name?.trim() ?? '—'}</td>
                  <td className="p-4">
                    <StatusBadge active={isActiveStatus(r.status)} />
                  </td>
                  <td className="p-4 text-muted-foreground whitespace-nowrap">{formatDateOnly(r.created_at)}</td>
                  <td className="p-4 text-muted-foreground whitespace-nowrap">—</td>
                </tr>
              ))}
          </tbody>
        </table>
        {loading && (
          <div className="p-8 text-center text-muted-foreground">Ładowanie subskrypcji…</div>
        )}
        {!loading && filteredRows.length === 0 && !loadError && (
          <div className="p-8 text-center text-muted-foreground">Brak rekordów spełniających kryteria.</div>
        )}
      </div>
    </div>
  )
}
