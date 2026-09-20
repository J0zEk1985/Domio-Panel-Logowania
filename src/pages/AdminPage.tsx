import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import {
  AlertTriangle,
  ChevronRight,
  CreditCard,
  DollarSign,
  FileText,
  Handshake,
  LayoutDashboard,
  Server,
  Settings,
  Shield,
  Tag,
  Users,
} from 'lucide-react'
import { supabase } from '../lib/supabase'
import { countPlatformVerificationAlerts } from '../lib/legalEntityAdminApi'
import { Navbar } from '../components/landing/Navbar'
import { Footer } from '../components/landing/Footer'
import PricingAdminTab from '../components/admin/PricingAdminTab'
import LegalAdminTab from '../components/admin/LegalAdminTab'
import UsersAndOrgsTab from '../components/admin/UsersAndOrgsTab'
import SubscriptionsAdminTab from '../components/admin/SubscriptionsAdminTab'
import PartnerOffersAdminTab from '../components/admin/PartnerOffersAdminTab'
import EntityVerificationAdminTab from '../components/admin/EntityVerificationAdminTab'
import PlatformContactAdminCard from '../components/admin/PlatformContactAdminCard'
import type { UsersOrgsSubTab } from '../components/admin/usersAndOrgsTypes'

function formatInt(n: number | null | undefined): string {
  if (n == null || Number.isNaN(n)) return '—'
  return n.toLocaleString('pl-PL')
}

function pendingVerificationCopy(count: number): string {
  const lastTwo = count % 100
  const last = count % 10
  if (count === 1) return '1 pozycja czeka na obsługę'
  if (lastTwo >= 12 && lastTwo <= 14) return `${count} pozycji czeka na obsługę`
  if (last >= 2 && last <= 4) return `${count} pozycje czekają na obsługę`
  return `${count} pozycji czeka na obsługę`
}

type AdminTab = 'dashboard' | 'users' | 'subscriptions' | 'pricing' | 'partner-offers' | 'legal' | 'settings' | 'entity-verification'

const sidebarNav: { id: AdminTab; label: string; icon: typeof LayoutDashboard }[] = [
  { id: 'dashboard', label: 'Pulpit', icon: LayoutDashboard },
  { id: 'entity-verification', label: 'Weryfikacja NIP', icon: AlertTriangle },
  { id: 'users', label: 'Użytkownicy i Firmy', icon: Users },
  { id: 'subscriptions', label: 'Globalne subskrypcje', icon: CreditCard },
  { id: 'pricing', label: 'Cennik i Promocje', icon: Tag },
  { id: 'partner-offers', label: 'Oferty Partnerskie', icon: Handshake },
  { id: 'legal', label: 'Dokumenty prawne', icon: FileText },
  { id: 'settings', label: 'Ustawienia', icon: Settings },
]

export default function AdminPage() {
  const [activeTab, setActiveTab] = useState<AdminTab>('dashboard')
  const [totalUsersCount, setTotalUsersCount] = useState<number | null>(null)
  const [activeSubscriptionsCount, setActiveSubscriptionsCount] = useState<number | null>(null)
  const [organizationsCount, setOrganizationsCount] = useState<number | null>(null)
  const [loading, setLoading] = useState(true)
  const [statsError, setStatsError] = useState<string | null>(null)
  const [verificationCount, setVerificationCount] = useState(0)
  const [usersTabSubTab, setUsersTabSubTab] = useState<UsersOrgsSubTab>('orgs')

  const openUsersTab = (subTab: UsersOrgsSubTab) => {
    setUsersTabSubTab(subTab)
    setActiveTab('users')
  }

  useEffect(() => {
    let cancelled = false

    const load = async () => {
      try {
        setLoading(true)
        setStatsError(null)

        const [usersCountRes, subsRes, orgsRes] = await Promise.all([
          supabase.from('profiles').select('*', { count: 'exact', head: true }),
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

        setTotalUsersCount(usersCountRes.count ?? null)
        setActiveSubscriptionsCount(subsRes.count ?? null)
        setOrganizationsCount(orgsRes.count ?? null)
        try {
          const pending = await countPlatformVerificationAlerts()
          if (!cancelled) setVerificationCount(pending)
        } catch (e) {
          console.error('[AdminPage] verification count:', e)
        }
      } catch (e) {
        console.error('[AdminPage] load error:', e)
        if (!cancelled) {
          setStatsError('Wystąpił błąd podczas ładowania danych.')
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

  const metrics = [
    {
      label: 'Użytkownicy',
      value: formatInt(totalUsersCount),
      icon: Users,
      hint: 'Otwórz listę',
      onOpen: () => openUsersTab('users'),
    },
    {
      label: 'Aktywne subskrypcje',
      value: formatInt(activeSubscriptionsCount),
      icon: DollarSign,
      hint: 'Otwórz listę',
      onOpen: () => setActiveTab('subscriptions'),
    },
    {
      label: 'Organizacje',
      value: formatInt(organizationsCount),
      icon: Server,
      hint: 'Otwórz listę',
      onOpen: () => openUsersTab('orgs'),
    },
  ]

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
                    onClick={() => {
                      if (item.id === 'users') setUsersTabSubTab('orgs')
                      setActiveTab(item.id)
                    }}
                    className={`w-full flex items-center gap-3 rounded-xl px-3 py-2.5 text-left text-sm transition-colors ${
                      isActive
                        ? 'bg-primary/10 text-primary font-medium'
                        : 'text-muted-foreground hover:bg-muted hover:text-foreground'
                    }`}
                  >
                    <Icon className={`h-5 w-5 shrink-0 ${isActive ? 'text-primary' : ''}`} />
                    <span className="leading-tight flex-1">{item.label}</span>
                    {item.id === 'entity-verification' && verificationCount > 0 ? (
                      <span className="rounded-full bg-amber-500 px-1.5 py-0.5 text-[10px] font-semibold text-amber-950">
                        {verificationCount > 99 ? '99+' : verificationCount}
                      </span>
                    ) : null}
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
                  className="grid sm:grid-cols-3 gap-4 mb-8"
                >
                  {metrics.map((m) => (
                    <button
                      key={m.label}
                      type="button"
                      onClick={m.onOpen}
                      className="bento-card text-left w-full transition-shadow hover:shadow-lg hover:shadow-primary/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    >
                      <div className="flex items-center justify-between mb-3">
                        <div className="p-2.5 rounded-xl bg-muted">
                          <m.icon className="h-5 w-5 text-primary" />
                        </div>
                        <span className="inline-flex items-center gap-1 text-xs text-primary font-medium bg-primary/5 px-2 py-1 rounded-full">
                          {m.hint}
                          <ChevronRight className="h-3.5 w-3.5" aria-hidden />
                        </span>
                      </div>
                      <p className="text-sm text-muted-foreground mb-1">{m.label}</p>
                      <p className="font-display text-2xl font-bold">{loading ? '…' : m.value}</p>
                    </button>
                  ))}
                </motion.div>

                {verificationCount > 0 && (
                  <motion.button
                    type="button"
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.2 }}
                    onClick={() => setActiveTab('entity-verification')}
                    className="w-full bento-card text-left flex items-center gap-4 hover:shadow-lg hover:shadow-primary/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                  >
                    <div className="p-2.5 rounded-xl bg-amber-500/15">
                      <AlertTriangle className="h-5 w-5 text-amber-600" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="font-display font-semibold">Wymagają uwagi</p>
                      <p className="text-sm text-muted-foreground">
                        Weryfikacja NIP — {pendingVerificationCopy(verificationCount)}
                      </p>
                    </div>
                    <ChevronRight className="h-5 w-5 text-muted-foreground shrink-0" aria-hidden />
                  </motion.button>
                )}
              </>
            )}

            {activeTab === 'entity-verification' && (
              <EntityVerificationAdminTab onCountChange={setVerificationCount} />
            )}

            {activeTab === 'users' && (
              <UsersAndOrgsTab initialSubTab={usersTabSubTab} />
            )}

            {activeTab === 'subscriptions' && <SubscriptionsAdminTab />}

            {activeTab === 'pricing' && <PricingAdminTab />}

            {activeTab === 'partner-offers' && <PartnerOffersAdminTab />}

            {activeTab === 'legal' && <LegalAdminTab />}

            {activeTab === 'settings' && <PlatformContactAdminCard />}
          </main>
        </div>
      </div>
      <Footer />
    </div>
  )
}
