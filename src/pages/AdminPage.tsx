import { useEffect, useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import {
  CreditCard,
  DollarSign,
  FileText,
  LayoutDashboard,
  MonitorSmartphone,
  Server,
  Shield,
  Tag,
  Users,
} from 'lucide-react'
import { supabase } from '../lib/supabase'
import { Navbar } from '../components/landing/Navbar'
import { Footer } from '../components/landing/Footer'
import PricingAdminTab from '../components/admin/PricingAdminTab'

type ProfileRow = {
  id: string
  full_name: string | null
  email: string | null
  platform_role: string | null
  account_type: string | null
  created_at: string | null
  updated_at: string | null
  last_login_at: string | null
}

function formatDateTime(iso: string | null | undefined): string {
  if (!iso) return '—'
  try {
    return new Intl.DateTimeFormat('pl-PL', {
      dateStyle: 'short',
      timeStyle: 'short',
    }).format(new Date(iso))
  } catch {
    return '—'
  }
}

function formatInt(n: number | null | undefined): string {
  if (n == null || Number.isNaN(n)) return '—'
  return n.toLocaleString('pl-PL')
}

type AdminTab = 'dashboard' | 'users' | 'subscriptions' | 'pricing' | 'legal' | 'cms'

const sidebarNav: { id: AdminTab; label: string; icon: typeof LayoutDashboard }[] = [
  { id: 'dashboard', label: 'Pulpit', icon: LayoutDashboard },
  { id: 'users', label: 'Użytkownicy i Firmy', icon: Users },
  { id: 'subscriptions', label: 'Subskrypcje', icon: CreditCard },
  { id: 'pricing', label: 'Cennik i Promocje', icon: Tag },
  { id: 'legal', label: 'Dokumenty prawne', icon: FileText },
  { id: 'cms', label: 'Treści strony (CMS)', icon: MonitorSmartphone },
]

export default function AdminPage() {
  const [activeTab, setActiveTab] = useState<AdminTab>('dashboard')
  const [totalUsersCount, setTotalUsersCount] = useState<number | null>(null)
  const [activeSubscriptionsCount, setActiveSubscriptionsCount] = useState<number | null>(null)
  const [organizationsCount, setOrganizationsCount] = useState<number | null>(null)
  const [profiles, setProfiles] = useState<ProfileRow[]>([])
  const [loading, setLoading] = useState(true)
  const [statsError, setStatsError] = useState<string | null>(null)
  const [tableError, setTableError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false

    const load = async () => {
      try {
        setLoading(true)
        setStatsError(null)
        setTableError(null)

        const [usersCountRes, profilesRes, subsRes, orgsRes] = await Promise.all([
          supabase.from('profiles').select('*', { count: 'exact', head: true }),
          supabase
            .from('profiles')
            .select(
              'id, full_name, email, platform_role, account_type, created_at, updated_at, last_login_at',
            )
            .order('updated_at', { ascending: false })
            .limit(20),
          supabase
            .from('org_subscriptions')
            .select('*', { count: 'exact', head: true })
            .eq('status', 'active'),
          supabase.from('organizations').select('*', { count: 'exact', head: true }),
        ])

        if (cancelled) return

        if (usersCountRes.error) {
          console.error('[AdminPage] profiles count error:', usersCountRes.error)
          setStatsError((prev) => prev ?? 'Nie udało się pobrać części statystyk.')
        }
        if (subsRes.error) {
          console.error('[AdminPage] org_subscriptions count error:', subsRes.error)
          setStatsError((prev) => prev ?? 'Nie udało się pobrać części statystyk.')
        }
        if (orgsRes.error) {
          console.error('[AdminPage] organizations count error:', orgsRes.error)
          setStatsError((prev) => prev ?? 'Nie udało się pobrać części statystyk.')
        }
        if (profilesRes.error) {
          console.error('[AdminPage] profiles list error:', profilesRes.error)
          setTableError('Nie udało się pobrać listy użytkowników (sprawdź polityki RLS).')
        }

        setTotalUsersCount(usersCountRes.count ?? null)
        setActiveSubscriptionsCount(subsRes.count ?? null)
        setOrganizationsCount(orgsRes.count ?? null)
        setProfiles((profilesRes.data as ProfileRow[] | null) ?? [])
      } catch (e) {
        console.error('[AdminPage] load error:', e)
        if (!cancelled) {
          setStatsError('Wystąpił błąd podczas ładowania danych.')
          setTableError('Wystąpił błąd podczas ładowania tabeli.')
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    }

    void load()
    return () => {
      cancelled = true
    }
  }, [])

  const metrics = useMemo(
    () => [
      {
        label: 'Użytkownicy',
        value: formatInt(totalUsersCount),
        icon: Users,
        change: '—',
      },
      {
        label: 'Aktywne subskrypcje',
        value: formatInt(activeSubscriptionsCount),
        icon: DollarSign,
        change: '—',
      },
      {
        label: 'Organizacje',
        value: formatInt(organizationsCount),
        icon: Server,
        change: '—',
      },
    ],
    [totalUsersCount, activeSubscriptionsCount, organizationsCount],
  )

  return (
    <div className="min-h-screen flex flex-col">
      <Navbar />
      <div className="pt-24 pb-16 px-4 flex-1">
        <div className="container mx-auto max-w-7xl flex flex-col lg:flex-row gap-8 lg:items-start">
          <aside className="w-full lg:w-64 shrink-0 lg:sticky lg:top-28">
            <nav className="bento-card p-2 space-y-1" aria-label="Menu panelu administratora">
              {sidebarNav.map((item) => {
                const Icon = item.icon
                const isActive = activeTab === item.id
                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => setActiveTab(item.id)}
                    className={`w-full flex items-center gap-3 rounded-xl px-3 py-2.5 text-left text-sm transition-colors ${
                      isActive
                        ? 'bg-primary/10 text-primary font-medium'
                        : 'text-muted-foreground hover:bg-muted hover:text-foreground'
                    }`}
                  >
                    <Icon className={`h-5 w-5 shrink-0 ${isActive ? 'text-primary' : ''}`} />
                    <span className="leading-tight">{item.label}</span>
                  </button>
                )
              })}
            </nav>
          </aside>

          <main className="flex-1 min-w-0">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="mb-10"
            >
              <h1 className="font-display text-3xl md:text-4xl font-bold mb-2 flex items-center gap-3">
                <Shield className="h-8 w-8 text-primary" />
                Panel <span className="gradient-brand-text">Administratora</span>
              </h1>
              <p className="text-muted-foreground text-lg">Zarządzaj platformą, użytkownikami i modułami.</p>
            </motion.div>

            {activeTab === 'dashboard' && (
              <>
                {statsError && (
                  <div className="mb-6 bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl">
                    {statsError}
                  </div>
                )}

                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.1 }}
                  className="grid sm:grid-cols-3 gap-4 mb-12"
                >
                  {metrics.map((m) => (
                    <div key={m.label} className="bento-card">
                      <div className="flex items-center justify-between mb-3">
                        <div className="p-2.5 rounded-xl bg-muted">
                          <m.icon className="h-5 w-5 text-primary" />
                        </div>
                        <span className="text-xs text-primary font-medium bg-primary/5 px-2 py-1 rounded-full">
                          {m.change}
                        </span>
                      </div>
                      <p className="text-sm text-muted-foreground mb-1">{m.label}</p>
                      <p className="font-display text-2xl font-bold">{loading ? '…' : m.value}</p>
                    </div>
                  ))}
                </motion.div>

                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.25 }}
                >
                  <h2 className="font-display text-xl font-semibold mb-4">Użytkownicy</h2>

                  {tableError && (
                    <div className="mb-4 bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl">
                      {tableError}
                    </div>
                  )}

                  <div className="bento-card overflow-x-auto p-0 sm:p-0">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-border/60 text-left text-muted-foreground">
                          <th className="p-4 font-medium">Imię i nazwisko</th>
                          <th className="p-4 font-medium">E-mail</th>
                          <th className="p-4 font-medium">Rola</th>
                          <th className="p-4 font-medium">Utworzono</th>
                          <th className="p-4 font-medium">Ostatnie logowanie</th>
                          <th className="p-4 font-medium text-right">Akcje</th>
                        </tr>
                      </thead>
                      <tbody>
                        {!loading &&
                          profiles.map((row) => (
                            <tr key={row.id} className="border-b border-border/40 last:border-0">
                              <td className="p-4 font-medium">
                                {row.full_name?.trim() ? row.full_name : '—'}
                              </td>
                              <td className="p-4 text-muted-foreground">{row.email ?? '—'}</td>
                              <td className="p-4">
                                {row.platform_role?.trim()
                                  ? row.platform_role
                                  : row.account_type?.trim()
                                    ? row.account_type
                                    : '—'}
                              </td>
                              <td className="p-4 text-muted-foreground">{formatDateTime(row.created_at)}</td>
                              <td className="p-4 text-muted-foreground">{formatDateTime(row.last_login_at)}</td>
                              <td className="p-4 text-right">
                                <button
                                  type="button"
                                  className="text-primary font-medium hover:underline"
                                  onClick={() => {
                                    console.log('[AdminPage] edit user id:', row.id)
                                  }}
                                >
                                  Edytuj
                                </button>
                              </td>
                            </tr>
                          ))}
                      </tbody>
                    </table>
                    {loading && (
                      <div className="p-8 text-center text-muted-foreground">Ładowanie użytkowników…</div>
                    )}
                    {!loading && profiles.length === 0 && !tableError && (
                      <div className="p-8 text-center text-muted-foreground">Brak rekordów do wyświetlenia.</div>
                    )}
                  </div>
                </motion.div>
              </>
            )}

            {activeTab === 'users' && (
              <div className="p-6 bento-card">
                <h2 className="font-display text-xl font-semibold mb-2">Użytkownicy i firmy</h2>
                <p className="text-muted-foreground">
                  Tutaj wdrożymy zarządzanie profilami użytkowników oraz organizacjami (firmami).
                </p>
              </div>
            )}

            {activeTab === 'subscriptions' && (
              <div className="p-6 bento-card">
                <h2 className="font-display text-xl font-semibold mb-2">Subskrypcje</h2>
                <p className="text-muted-foreground">
                  Tutaj wdrożymy przegląd i edycję subskrypcji organizacji (np. tabela org_subscriptions).
                </p>
              </div>
            )}

            {activeTab === 'pricing' && <PricingAdminTab />}

            {activeTab === 'legal' && (
              <div className="p-6 bento-card">
                <h2 className="font-display text-xl font-semibold mb-2">Dokumenty prawne</h2>
                <p className="text-muted-foreground">
                  Tutaj wdrożymy edycję regulaminów, polityk prywatności i innych dokumentów prawnych.
                </p>
              </div>
            )}

            {activeTab === 'cms' && (
              <div className="p-6 bento-card">
                <h2 className="font-display text-xl font-semibold mb-2">Treści strony (CMS)</h2>
                <p className="text-muted-foreground">
                  Tutaj wdrożymy zarządzanie treściami marketingowymi i sekcjami strony publicznej.
                </p>
              </div>
            )}
          </main>
        </div>
      </div>
      <Footer />
    </div>
  )
}
