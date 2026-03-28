import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { motion } from 'framer-motion'
import type { LucideIcon } from 'lucide-react'
import {
  Building2,
  Car,
  LayoutGrid,
  ShieldCheck,
  ShoppingCart,
  Sparkles,
  TrendingUp,
  Wrench,
  Zap,
} from 'lucide-react'
import { supabase } from '../lib/supabase'
import { Application } from '../types/database'
import { Navbar } from '../components/landing/Navbar'
import { Footer } from '../components/landing/Footer'

/** Map application name/URLs to icons (fallback: LayoutGrid). */
function iconForApplication(app: Application): LucideIcon {
  const blob = `${app.name} ${app.domain_url ?? ''} ${app.api_url ?? ''}`.toLowerCase()
  if (blob.includes('clean')) return Sparkles
  if (blob.includes('flot') || blob.includes('fleet') || blob.includes('car')) return Car
  if (blob.includes('serwis') || blob.includes('service')) return Wrench
  if (blob.includes('nieruchom') || blob.includes('biznes') || blob.includes('building')) return Building2
  if (blob.includes('bezpiecz') || blob.includes('security') || blob.includes('shield')) return ShieldCheck
  return LayoutGrid
}

const statusBadgeClass: Record<'free' | 'paid', string> = {
  free: 'bg-accent/10 text-accent border-accent/20',
  paid: 'bg-primary/10 text-primary border-primary/20',
}

const statusLabel: Record<'free' | 'paid', string> = {
  free: 'Darmowy',
  paid: 'Aktywny',
}

interface MarketplaceModule {
  name: string
  icon: LucideIcon
  price: string
  description: string
  suggestion?: string
}

const marketplaceModules: MarketplaceModule[] = [
  {
    name: 'Flota DOMIO',
    icon: Car,
    price: '49 zł/mies.',
    description: 'Zarządzanie flotą pojazdów',
    suggestion: 'Skoro korzystasz z Cleaning, wypróbuj Flotę!',
  },
  {
    name: 'Serwis DOMIO',
    icon: Wrench,
    price: '39 zł/mies.',
    description: 'Zgłoszenia serwisowe i naprawy',
  },
]

export default function DashboardPage() {
  const [apps, setApps] = useState<Application[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()

  useEffect(() => {
    const loadUserApps = async () => {
      try {
        const {
          data: { user },
        } = await supabase.auth.getUser()

        if (!user) {
          navigate('/login')
          return
        }

        console.log('[SSO DEBUG] User verified:', user.id)

        // Check if returnTo parameter exists (must match LoginPage.tsx which uses 'returnTo')
        const returnTo = searchParams.get('returnTo')
        if (returnTo) {
          console.log('[SSO DEBUG] Redirecting to returnTo:', returnTo)
          window.location.href = returnTo
          return
        }

        // --- Dispatcher: fleet vs cleaning access ---
        // 1. Fetch profile (fleet_role, first-login flag)
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('fleet_role, is_first_login')
          .eq('id', user.id)
          .maybeSingle()

        if (profileError) {
          console.log('[SSO DEBUG] Profile fetch error (fleet_role):', profileError.message)
        }
        if (profile?.is_first_login === true) {
          navigate('/change-password')
          return
        }
        const fleetRole = profile?.fleet_role ?? null
        console.log('[SSO DEBUG] fleet_role:', fleetRole ?? '(empty)')

        // 2. Fetch memberships (cleaning system roles)
        const { data: membershipsData, error: membershipsError } = await supabase
          .from('memberships')
          .select('role')
          .eq('user_id', user.id)

        if (membershipsError) {
          console.log('[SSO DEBUG] Memberships fetch error:', membershipsError.message)
        }
        const membershipCount = membershipsData?.length ?? 0
        console.log(
          '[SSO DEBUG] memberships count:',
          membershipCount,
          membershipCount ? `(roles: ${membershipsData!.map((m) => m.role).join(', ')})` : '',
        )

        // 3. Dispatcher condition
        const hasFleetAccess = fleetRole === 'admin' || fleetRole === 'driver'
        const hasCleaningAccess = membershipCount > 0
        console.log('[SSO DEBUG] hasFleetAccess:', hasFleetAccess, '| hasCleaningAccess:', hasCleaningAccess)

        if (hasFleetAccess && !hasCleaningAccess) {
          console.log('[SSO DEBUG] Redirecting fleet-only user to flota.domio.com.pl')
          window.location.href = 'https://flota.domio.com.pl'
          return
        }

        console.log('[SSO DEBUG] User has dashboard access, loading applications')

        // 4. Fetch applications (only when not redirected)
        const { data: appsData, error: appsError } = await supabase
          .from('applications')
          .select('*')
          .eq('is_active', true)
          .order('name', { ascending: true })

        if (appsError) throw appsError

        setApps(appsData || [])
      } catch (err) {
        // Ignore AbortError from tab suspension
        if (err instanceof Error && err.name === 'AbortError') {
          console.log('[DashboardPage] Request aborted (tab suspended)')
        } else {
          console.error('Error loading apps:', err)
          setError(err instanceof Error ? err.message : 'Wystąpił błąd podczas ładowania aplikacji')
        }
      } finally {
        setLoading(false)
      }
    }

    loadUserApps()
  }, [navigate, searchParams])

  const handleAppClick = (app: Application) => {
    if (app.domain_url) {
      window.location.href = app.domain_url
    } else if (app.api_url) {
      window.location.href = app.api_url
    }
  }

  const handleLogout = async () => {
    // Optimistic logout: clear local state immediately, redirect to login with logout=true, then sign out in background
    // 1. Clear localStorage immediately
    try {
      const keysToRemove: string[] = []
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i)
        if (key && (key.startsWith('sb-') || key.includes('supabase') || key.includes('domio-auth'))) {
          keysToRemove.push(key)
        }
      }
      keysToRemove.forEach((key) => localStorage.removeItem(key))
    } catch (e) {
      console.error('[DashboardPage] Error clearing localStorage:', e)
    }

    // 2. Redirect immediately to the login page with logout=true parameter
    // Use window.location.href to force full page reload and proper cleanup
    window.location.href = '/login?logout=true'

    // 3. Sign out in background (non-blocking) - will be handled by LoginPage
    supabase.auth.signOut().catch((e) => {
      console.error('[DashboardPage] Error during background signOut:', e)
    })
  }

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <Navbar isAuthenticated />

      <div className="flex-1 pt-24 pb-16 px-4">
        <div className="container mx-auto max-w-6xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-10 flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between"
          >
            <div>
              <h1 className="font-display text-3xl md:text-4xl font-bold mb-2">
                Witaj w <span className="gradient-brand-text">panelu DOMIO</span>
              </h1>
              <p className="text-muted-foreground text-lg">Zarządzaj swoimi modułami i odkrywaj nowe możliwości.</p>
            </div>
            <button
              type="button"
              onClick={handleLogout}
              className="shrink-0 rounded-md border border-border bg-card px-4 py-2 text-sm font-medium text-foreground hover:bg-muted/60 transition-colors"
            >
              Wyloguj się
            </button>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="mb-12"
          >
            <h2 className="font-display text-xl font-semibold mb-4 flex items-center gap-2">
              <Zap className="h-5 w-5 text-primary" aria-hidden />
              Twoje moduły
            </h2>

            {loading && (
              <div className="text-center py-16 rounded-2xl border border-border/50 bg-card/40">
                <p className="text-muted-foreground text-lg">Ładowanie aplikacji...</p>
              </div>
            )}

            {error && (
              <div className="mb-6 bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl">
                {error}
              </div>
            )}

            {!loading && !error && apps.length === 0 && (
              <div className="text-center py-16 rounded-2xl border border-dashed border-border bg-muted/20">
                <p className="text-muted-foreground text-lg">Brak dostępnych aplikacji</p>
              </div>
            )}

            {!loading && !error && apps.length > 0 && (
              <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
                {apps.map((app) => {
                  const Icon = iconForApplication(app)
                  const tier: 'free' | 'paid' = app.is_free ? 'free' : 'paid'
                  return (
                    <motion.div
                      key={app.id}
                      role="button"
                      tabIndex={0}
                      onClick={() => handleAppClick(app)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' || e.key === ' ') {
                          e.preventDefault()
                          handleAppClick(app)
                        }
                      }}
                      whileHover={{ y: -6 }}
                      transition={{ type: 'spring', stiffness: 400, damping: 28 }}
                      className="bento-card cursor-pointer text-left outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    >
                      <div className="flex items-start justify-between mb-3">
                        <div className="p-2.5 rounded-xl bg-muted">
                          <Icon className="h-5 w-5 text-primary" aria-hidden />
                        </div>
                        <span
                          className={`inline-flex items-center rounded-md border px-2 py-0.5 text-xs font-medium ${statusBadgeClass[tier]}`}
                        >
                          {statusLabel[tier]}
                        </span>
                      </div>
                      <h3 className="font-display font-semibold mb-1">{app.name}</h3>
                      <p className="text-sm text-muted-foreground">
                        {app.is_free ? 'Moduł dostępny bezpłatnie.' : 'Subskrypcja aktywna — kliknij, aby otworzyć.'}
                      </p>
                      <span className="mt-4 inline-flex text-sm font-medium text-primary">Otwórz →</span>
                    </motion.div>
                  )
                })}
              </div>
            )}
          </motion.div>

          {!loading && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
            >
              <h2 className="font-display text-xl font-semibold mb-4 flex items-center gap-2">
                <ShoppingCart className="h-5 w-5 text-accent" aria-hidden />
                Sklep / Marketplace
              </h2>
              <div className="grid sm:grid-cols-2 gap-4">
                {marketplaceModules.map((mod) => (
                  <div key={mod.name} className="bento-card relative overflow-hidden">
                    {mod.suggestion && (
                      <div className="flex items-center gap-1.5 mb-3 text-xs text-primary bg-primary/5 px-3 py-1.5 rounded-full w-fit">
                        <TrendingUp className="h-3 w-3 shrink-0" aria-hidden />
                        {mod.suggestion}
                      </div>
                    )}
                    <div className="flex items-start gap-4">
                      <div className="p-2.5 rounded-xl bg-muted shrink-0">
                        <mod.icon className="h-5 w-5 text-accent" aria-hidden />
                      </div>
                      <div className="flex-1 min-w-0">
                        <h3 className="font-display font-semibold mb-1">{mod.name}</h3>
                        <p className="text-sm text-muted-foreground mb-3">{mod.description}</p>
                        <div className="flex flex-wrap items-center justify-between gap-2">
                          <span className="font-display font-bold text-foreground">{mod.price}</span>
                          <button
                            type="button"
                            className="inline-flex h-9 items-center justify-center rounded-md gradient-brand px-4 text-sm font-medium text-primary-foreground shadow-sm hover:opacity-95"
                          >
                            Kup moduł
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </motion.div>
          )}
        </div>
      </div>

      <Footer />
    </div>
  )
}
