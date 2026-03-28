import { useCallback, useEffect, useState } from 'react'
import { ArrowDown, ArrowUp, Building2, Search, UserCircle } from 'lucide-react'
import type { PostgrestError } from '@supabase/supabase-js'
import { supabase } from '../../lib/supabase'
import { inputClass } from './pricingAdminUtils'
import OrganizationDetail from './OrganizationDetail'
import UserDetail from './UserDetail'
import type {
  OrganizationListRow,
  OrgSortConfig,
  OrgSortKey,
  ProfileListRow,
  UserSortConfig,
  UserSortKey,
  UsersOrgsSubTab,
} from './usersAndOrgsTypes'
import { formatDateTime } from './usersAndOrgsUtils'

/** Surfaces PostgREST / Postgres details in UI and logs (not generic RLS text). */
function formatSupabaseError(err: PostgrestError | Error | null | undefined): string {
  if (err == null) return 'Nieznany błąd'
  const parts: string[] = []
  if ('message' in err && err.message) parts.push(err.message)
  if ('details' in err && err.details) parts.push(`Szczegóły: ${String(err.details)}`)
  if ('hint' in err && err.hint) parts.push(`Podpowiedź: ${String(err.hint)}`)
  if ('code' in err && err.code) parts.push(`Kod: ${String(err.code)}`)
  return parts.length > 0 ? parts.join(' · ') : String(err)
}

function OrgSortableTh({
  label,
  sortKey,
  currentSort,
  onSort,
}: {
  label: string
  sortKey: OrgSortKey
  currentSort: OrgSortConfig
  onSort: (k: OrgSortKey) => void
}) {
  const active = currentSort.key === sortKey
  return (
    <th className="p-4 font-medium">
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

function UserSortableTh({
  label,
  sortKey,
  currentSort,
  onSort,
}: {
  label: string
  sortKey: UserSortKey
  currentSort: UserSortConfig
  onSort: (k: UserSortKey) => void
}) {
  const active = currentSort.key === sortKey
  return (
    <th className="p-4 font-medium">
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

export default function UsersAndOrgsTab() {
  const [activeSubTab, setActiveSubTab] = useState<UsersOrgsSubTab>('orgs')
  const [searchQuery, setSearchQuery] = useState('')
  const [debouncedSearch, setDebouncedSearch] = useState('')
  const [orgSort, setOrgSort] = useState<OrgSortConfig>({ key: 'name', direction: 'asc' })
  const [userSort, setUserSort] = useState<UserSortConfig>({ key: 'last_login_at', direction: 'desc' })
  const [selectedOrg, setSelectedOrg] = useState<string | null>(null)
  const [selectedUser, setSelectedUser] = useState<string | null>(null)

  const [orgs, setOrgs] = useState<OrganizationListRow[]>([])
  const [users, setUsers] = useState<ProfileListRow[]>([])
  const [loading, setLoading] = useState(true)
  const [listError, setListError] = useState<string | null>(null)

  useEffect(() => {
    const id = window.setTimeout(() => setDebouncedSearch(searchQuery), 300)
    return () => window.clearTimeout(id)
  }, [searchQuery])

  const handleOrgSort = useCallback((key: OrgSortKey) => {
    setOrgSort((prev) =>
      prev.key === key
        ? { key, direction: prev.direction === 'asc' ? 'desc' : 'asc' }
        : { key, direction: 'asc' },
    )
  }, [])

  const handleUserSort = useCallback((key: UserSortKey) => {
    setUserSort((prev) =>
      prev.key === key
        ? { key, direction: prev.direction === 'asc' ? 'desc' : 'asc' }
        : { key, direction: 'asc' },
    )
  }, [])

  const loadOrgs = useCallback(async () => {
    setListError(null)
    try {
      const key = orgSort.key
      const ascending = orgSort.direction === 'asc'
      let q = supabase
        .from('organizations')
        .select('id, name, nip, city, created_at')
        .order(key, { ascending })
        .limit(10)

      const term = debouncedSearch.trim()
      if (term) {
        const pattern = `%${term.replace(/%/g, '\\%').replace(/_/g, '\\_')}%`
        q = q.ilike('name', pattern)
      }

      const { data, error } = await q
      if (error) {
        console.error('SUPABASE ERROR:', error)
        setListError(formatSupabaseError(error))
        setOrgs([])
        return
      }
      setOrgs((data as OrganizationListRow[]) ?? [])
    } catch (e) {
      console.error('[UsersAndOrgsTab] loadOrgs:', e)
      setListError(e instanceof Error ? e.message : 'Wystąpił błąd podczas ładowania firm.')
      setOrgs([])
    }
  }, [debouncedSearch, orgSort])

  const loadUsers = useCallback(async () => {
    setListError(null)
    try {
      const key = userSort.key
      const ascending = userSort.direction === 'asc'
      let query = supabase.from('profiles').select('*')
      const searchQuery = debouncedSearch.trim()
      if (searchQuery) {
        const pattern = `%${searchQuery.replace(/%/g, '\\%').replace(/_/g, '\\_')}%`
        query = query.or(`email.ilike.${pattern},first_name.ilike.${pattern},last_name.ilike.${pattern}`)
      }
      query = query.order(key, { ascending }).limit(10)

      const { data, error } = await query
      if (error) {
        console.error('SUPABASE ERROR:', error)
        setListError(formatSupabaseError(error))
        setUsers([])
        return
      }
      setUsers((data as ProfileListRow[]) ?? [])
    } catch (e) {
      console.error('[UsersAndOrgsTab] loadUsers:', e)
      setListError(e instanceof Error ? e.message : 'Wystąpił błąd podczas ładowania użytkowników.')
      setUsers([])
    }
  }, [debouncedSearch, userSort])

  useEffect(() => {
    if (selectedOrg != null || selectedUser != null) return
    let cancelled = false
    const run = async () => {
      setLoading(true)
      if (activeSubTab === 'orgs') {
        await loadOrgs()
      } else {
        await loadUsers()
      }
      if (!cancelled) setLoading(false)
    }
    void run()
    return () => {
      cancelled = true
    }
  }, [activeSubTab, debouncedSearch, orgSort, userSort, selectedOrg, selectedUser, loadOrgs, loadUsers])

  if (selectedOrg) {
    return (
      <OrganizationDetail
        organizationId={selectedOrg}
        onBack={() => {
          setSelectedOrg(null)
        }}
        onUserClick={(userId) => {
          setSelectedOrg(null)
          setSelectedUser(userId)
          setActiveSubTab('users')
        }}
      />
    )
  }

  if (selectedUser) {
    return <UserDetail userId={selectedUser} onBack={() => setSelectedUser(null)} />
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="font-display text-xl font-semibold mb-1">Użytkownicy i firmy</h2>
        <p className="text-muted-foreground text-sm">
          Przeglądaj organizacje i profile użytkowników (max. 10 wyników na listę). Użyj wyszukiwania i nagłówków kolumn
          do sortowania.
        </p>
      </div>

      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          onClick={() => {
            setActiveSubTab('orgs')
            setOrgSort({ key: 'name', direction: 'asc' })
          }}
          className={`inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-colors ${
            activeSubTab === 'orgs'
              ? 'bg-primary/10 text-primary'
              : 'text-muted-foreground hover:bg-muted hover:text-foreground'
          }`}
        >
          <Building2 className="h-4 w-4 shrink-0" />
          Firmy
        </button>
        <button
          type="button"
          onClick={() => {
            setActiveSubTab('users')
            setUserSort({ key: 'last_login_at', direction: 'desc' })
          }}
          className={`inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-colors ${
            activeSubTab === 'users'
              ? 'bg-primary/10 text-primary'
              : 'text-muted-foreground hover:bg-muted hover:text-foreground'
          }`}
        >
          <UserCircle className="h-4 w-4 shrink-0" />
          Użytkownicy
        </button>
      </div>

      <div className="relative max-w-md">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
        <input
          className={`${inputClass} pl-10`}
          placeholder={activeSubTab === 'orgs' ? 'Szukaj po nazwie firmy…' : 'Szukaj po e-mailu lub imieniu i nazwisku…'}
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          aria-label="Wyszukiwarka"
        />
      </div>

      {listError && (
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm break-words">
          {listError}
        </div>
      )}

      <div className="bento-card overflow-x-auto p-0 sm:p-0">
        {activeSubTab === 'orgs' ? (
          <table className="w-full text-sm min-w-[40rem]">
            <thead>
              <tr className="border-b border-border/60 text-left">
                <OrgSortableTh
                  label="Nazwa"
                  sortKey="name"
                  currentSort={orgSort}
                  onSort={handleOrgSort}
                />
                <OrgSortableTh label="NIP" sortKey="nip" currentSort={orgSort} onSort={handleOrgSort} />
                <OrgSortableTh label="Miasto" sortKey="city" currentSort={orgSort} onSort={handleOrgSort} />
                <OrgSortableTh
                  label="Data utworzenia"
                  sortKey="created_at"
                  currentSort={orgSort}
                  onSort={handleOrgSort}
                />
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={4} className="p-8 text-center text-muted-foreground">
                    Ładowanie…
                  </td>
                </tr>
              )}
              {!loading &&
                orgs.map((row) => (
                  <tr
                    key={row.id}
                    className="border-b border-border/40 last:border-0 cursor-pointer hover:bg-muted/40"
                    onClick={() => setSelectedOrg(row.id)}
                  >
                    <td className="p-4 font-medium">{row.name}</td>
                    <td className="p-4 text-muted-foreground">{row.nip?.trim() ?? '—'}</td>
                    <td className="p-4 text-muted-foreground">{row.city?.trim() ?? '—'}</td>
                    <td className="p-4 text-muted-foreground">{formatDateTime(row.created_at)}</td>
                  </tr>
                ))}
            </tbody>
          </table>
        ) : (
          <table className="w-full text-sm min-w-[44rem]">
            <thead>
              <tr className="border-b border-border/60 text-left">
                <UserSortableTh
                  label="Imię i nazwisko"
                  sortKey="last_name"
                  currentSort={userSort}
                  onSort={handleUserSort}
                />
                <UserSortableTh label="Email" sortKey="email" currentSort={userSort} onSort={handleUserSort} />
                <UserSortableTh
                  label="Rola platformowa"
                  sortKey="platform_role"
                  currentSort={userSort}
                  onSort={handleUserSort}
                />
                <UserSortableTh
                  label="Ostatnie logowanie"
                  sortKey="last_login_at"
                  currentSort={userSort}
                  onSort={handleUserSort}
                />
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={4} className="p-8 text-center text-muted-foreground">
                    Ładowanie…
                  </td>
                </tr>
              )}
              {!loading &&
                users.map((user) => (
                  <tr
                    key={user.id}
                    className="border-b border-border/40 last:border-0 cursor-pointer hover:bg-muted/50 transition-colors"
                    onClick={() => setSelectedUser(user.id)}
                  >
                    <td className="p-4 font-medium">
                      {[user.first_name?.trim(), user.last_name?.trim()].filter(Boolean).join(' ') ||
                        user.full_name?.trim() ||
                        '—'}
                    </td>
                    <td className="p-4 text-muted-foreground">{user.email?.trim() ?? '—'}</td>
                    <td className="p-4">{user.platform_role?.trim() ?? '—'}</td>
                    <td className="p-4 text-muted-foreground">{formatDateTime(user.last_login_at)}</td>
                  </tr>
                ))}
            </tbody>
          </table>
        )}
        {!loading && activeSubTab === 'orgs' && orgs.length === 0 && !listError && (
          <div className="p-8 text-center text-muted-foreground">Brak firm spełniających kryteria.</div>
        )}
        {!loading && activeSubTab === 'users' && users.length === 0 && !listError && (
          <div className="p-8 text-center text-muted-foreground">Brak użytkowników spełniających kryteria.</div>
        )}
      </div>
    </div>
  )
}
