import { useCallback, useEffect, useState } from 'react'
import { ArrowDown, ArrowUp, Building2, Search, UserCircle } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { inputClass } from './pricingAdminUtils'
import OrganizationDetail from './OrganizationDetail'
import UserDetail from './UserDetail'
import type {
  OrganizationListRow,
  OrgSortKey,
  ProfileListRow,
  UserSortKey,
  UsersOrgsSubTab,
} from './usersAndOrgsTypes'
import { displayPersonName, formatDateTime } from './usersAndOrgsUtils'

type SortConfig = { key: string; direction: 'asc' | 'desc' }

function SortableTh({
  label,
  sortKey,
  currentSort,
  onSort,
}: {
  label: string
  sortKey: string
  currentSort: SortConfig
  onSort: (k: string) => void
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
  const [sortConfig, setSortConfig] = useState<SortConfig>({ key: 'name', direction: 'asc' })
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

  const handleSort = useCallback((key: string) => {
    setSortConfig((prev) =>
      prev.key === key
        ? { key, direction: prev.direction === 'asc' ? 'desc' : 'asc' }
        : { key, direction: 'asc' },
    )
  }, [])

  const loadOrgs = useCallback(async () => {
    setListError(null)
    try {
      const key = sortConfig.key as OrgSortKey
      const ascending = sortConfig.direction === 'asc'
      let q = supabase
        .from('organizations')
        .select('id, name, nip, city, created_at')
        .order(key, { ascending, nullsFirst: false })
        .limit(10)

      const term = debouncedSearch.trim()
      if (term) {
        const pattern = `%${term.replace(/%/g, '\\%').replace(/_/g, '\\_')}%`
        q = q.ilike('name', pattern)
      }

      const { data, error } = await q
      if (error) {
        console.error('[UsersAndOrgsTab] organizations:', error)
        setListError('Nie udało się pobrać listy firm (sprawdź kolumny NIP/miasto po migracji i RLS).')
        setOrgs([])
        return
      }
      setOrgs((data as OrganizationListRow[]) ?? [])
    } catch (e) {
      console.error('[UsersAndOrgsTab] loadOrgs:', e)
      setListError('Wystąpił błąd podczas ładowania firm.')
      setOrgs([])
    }
  }, [debouncedSearch, sortConfig])

  const loadUsers = useCallback(async () => {
    setListError(null)
    try {
      const key = sortConfig.key as UserSortKey
      const ascending = sortConfig.direction === 'asc'
      let q = supabase
        .from('profiles')
        .select('id, first_name, last_name, full_name, email, platform_role, last_login_at')
        .order(key, { ascending, nullsFirst: false })
        .limit(10)

      const term = debouncedSearch.trim()
      if (term) {
        const pattern = `%${term.replace(/%/g, '\\%').replace(/_/g, '\\_')}%`
        q = q.or(
          `email.ilike.${pattern},full_name.ilike.${pattern},first_name.ilike.${pattern},last_name.ilike.${pattern}`,
        )
      }

      const { data, error } = await q
      if (error) {
        console.error('[UsersAndOrgsTab] profiles:', error)
        setListError('Nie udało się pobrać listy użytkowników (sprawdź RLS).')
        setUsers([])
        return
      }
      setUsers((data as ProfileListRow[]) ?? [])
    } catch (e) {
      console.error('[UsersAndOrgsTab] loadUsers:', e)
      setListError('Wystąpił błąd podczas ładowania użytkowników.')
      setUsers([])
    }
  }, [debouncedSearch, sortConfig])

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
  }, [activeSubTab, debouncedSearch, sortConfig, selectedOrg, selectedUser, loadOrgs, loadUsers])

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
    return (
      <UserDetail
        userId={selectedUser}
        onBack={() => {
          setSelectedUser(null)
        }}
      />
    )
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
            setSortConfig({ key: 'name', direction: 'asc' })
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
            setSortConfig({ key: 'last_login_at', direction: 'desc' })
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
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {listError}
        </div>
      )}

      <div className="bento-card overflow-x-auto p-0 sm:p-0">
        {activeSubTab === 'orgs' ? (
          <table className="w-full text-sm min-w-[40rem]">
            <thead>
              <tr className="border-b border-border/60 text-left">
                <SortableTh
                  label="Nazwa"
                  sortKey="name"
                  currentSort={sortConfig}
                  onSort={handleSort}
                />
                <SortableTh label="NIP" sortKey="nip" currentSort={sortConfig} onSort={handleSort} />
                <SortableTh label="Miasto" sortKey="city" currentSort={sortConfig} onSort={handleSort} />
                <SortableTh
                  label="Data utworzenia"
                  sortKey="created_at"
                  currentSort={sortConfig}
                  onSort={handleSort}
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
                <SortableTh
                  label="Imię i nazwisko"
                  sortKey="full_name"
                  currentSort={sortConfig}
                  onSort={handleSort}
                />
                <SortableTh label="Email" sortKey="email" currentSort={sortConfig} onSort={handleSort} />
                <SortableTh
                  label="Rola platformowa"
                  sortKey="platform_role"
                  currentSort={sortConfig}
                  onSort={handleSort}
                />
                <SortableTh
                  label="Ostatnie logowanie"
                  sortKey="last_login_at"
                  currentSort={sortConfig}
                  onSort={handleSort}
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
                users.map((row) => (
                  <tr
                    key={row.id}
                    className="border-b border-border/40 last:border-0 cursor-pointer hover:bg-muted/40"
                    onClick={() => setSelectedUser(row.id)}
                  >
                    <td className="p-4 font-medium">{displayPersonName(row)}</td>
                    <td className="p-4 text-muted-foreground">{row.email?.trim() ?? '—'}</td>
                    <td className="p-4">{row.platform_role?.trim() ?? '—'}</td>
                    <td className="p-4 text-muted-foreground">{formatDateTime(row.last_login_at)}</td>
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
