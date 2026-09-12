import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useLocation, Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import type { LucideIcon } from 'lucide-react'
import {
  Building2,
  Car,
  Home,
  LayoutGrid,
  ShieldCheck,
  ShoppingCart,
  Sparkles,
  Wrench,
  Zap,
} from 'lucide-react'
import { Application } from '../types/database'
import { Navbar } from '../components/landing/Navbar'
import { Footer } from '../components/landing/Footer'
import { DashboardModuleCard } from '../components/dashboard/DashboardModuleCard'
import { ModulePlanDialog } from '../components/dashboard/ModulePlanDialog'
import { OrgInboundMailboxesCard } from '../components/dashboard/OrgInboundMailboxesCard'
import {
  applicationMatchesModuleSlug,
  catalogModuleForApplication,
  sortApplicationsByCatalog,
} from '../lib/moduleAccess'
import { getLandingModules } from '../data/modules'
import { useDashboardApps } from '../hooks/useDashboardApps'
import {
  currentPlanForApp,
  isOrgSubscriptionActive,
  type OrgSubscriptionView,
} from '../lib/orgBilling'
import { planPriceLabel } from '../lib/pricingDisplay'

function iconForApplication(app: Application): LucideIcon {
  const catalogIcon = catalogModuleForApplication(app)?.icon
  if (catalogIcon) return catalogIcon
  const blob = `${app.name} ${app.domain_url ?? ''} ${app.api_url ?? ''}`.toLowerCase()
  if (blob.includes('clean')) return Sparkles
  if (blob.includes('flot') || blob.includes('fleet') || blob.includes('car')) return Car
  if (blob.includes('serwis') || blob.includes('service')) return Wrench
  if (blob.includes('home') || blob.includes('mieszkan')) return Home
  if (blob.includes('administr') || blob.includes('nieruchom') || blob.includes('building')) return Building2
  if (blob.includes('bezpiecz') || blob.includes('security') || blob.includes('shield')) return ShieldCheck
  return LayoutGrid
}

function displayApplicationName(app: Application): string {
  return catalogModuleForApplication(app)?.name ?? app.name
}

function displayApplicationDescription(app: Application): string {
  const catalog = catalogModuleForApplication(app)
  if (catalog?.shortDescription) return catalog.shortDescription
  return app.is_free ? 'Moduł dostępny bezpłatnie.' : 'Subskrypcja aktywna — kliknij, aby otworzyć.'
}

const statusBadgeClass: Record<'free' | 'paid', string> = {
  free: 'bg-accent/10 text-accent border-accent/20',
  paid: 'bg-primary/10 text-primary border-primary/20',
}

const statusLabel: Record<'free' | 'paid', string> = {
  free: 'Darmowy',
  paid: 'Aktywny',
}

export default function DashboardPage() {
  const [noAdminBanner, setNoAdminBanner] = useState(false)
  const [planDialogApp, setPlanDialogApp] = useState<Application | null>(null)
  const navigate = useNavigate()
  const location = useLocation()
  const {
    apps,
    setApps,
    allProductApps,
    loading,
    error,
    isPlatformAdmin,
    billingOrgId,
    canManageBilling,
    subsByAppId,
    setSubsByAppId,
    plansByAppId,
  } = useDashboardApps()

  useEffect(() => {
    const st = location.state as { noAdminAccess?: boolean } | undefined
    if (st?.noAdminAccess) {
      setNoAdminBanner(true)
      navigate(location.pathname, { replace: true, state: {} })
    }
  }, [location.pathname, location.state, navigate])

  const handleAppClick = (app: Application) => {
    if (app.domain_url) {
      window.location.href = app.domain_url
    } else if (app.api_url) {
      window.location.href = app.api_url
    }
  }

  const extraModules = useMemo(
    () =>
      getLandingModules()
        .map((mod) => ({
          mod,
          app: allProductApps.find((row) => applicationMatchesModuleSlug(row, mod.slug)) ?? null,
        }))
        .filter(
          ({ app, mod }) =>
            !apps.some((visible) => applicationMatchesModuleSlug(visible, mod.slug) || visible.id === app?.id),
        ),
    [allProductApps, apps],
  )

  const planSummaryFor = (app: Application): string | null => {
    if (app.is_free) return 'Plan: bezpłatny'
    const sub = subsByAppId.get(app.id) ?? null
    const plans = plansByAppId.get(app.id) ?? []
    if (!isOrgSubscriptionActive(sub)) return 'Brak aktywnego planu'
    const plan = currentPlanForApp(plans, sub)
    if (!plan) return 'Subskrypcja aktywna'
    return `Plan ${plan.name} · ${planPriceLabel(plan, sub?.billing_interval === 'yearly')}`
  }

  const applySubscriptionChange = (next: OrgSubscriptionView) => {
    setSubsByAppId((prev) => {
      const map = new Map(prev)
      map.set(next.app_id, next)
      return map
    })
    const active = isOrgSubscriptionActive(next)
    if (active) {
      const product = allProductApps.find((row) => row.id === next.app_id)
      if (product) {
        setApps((prev) => (prev.some((row) => row.id === product.id) ? prev : sortApplicationsByCatalog([...prev, product])))
      }
      return
    }
    if (!isPlatformAdmin) {
      setApps((prev) => prev.filter((row) => row.id !== next.app_id))
    }
  }

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <Navbar />

      <div className="flex-1 pt-24 pb-16 px-4">
        <div className="container mx-auto max-w-6xl">
          {noAdminBanner && (
            <div
              className="mb-6 bg-amber-500/10 border border-amber-500/30 text-foreground px-4 py-3 rounded-xl"
              role="status"
            >
              Brak uprawnień do panelu administratora.
            </div>
          )}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="mb-10">
            <h1 className="font-display text-3xl md:text-4xl font-bold mb-2">
              Witaj w <span className="gradient-brand-text">panelu DOMIO</span>
            </h1>
            <p className="text-muted-foreground text-lg">Zarządzaj swoimi modułami i odkrywaj nowe możliwości.</p>
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
                  const catalog = catalogModuleForApplication(app)
                  const Icon = iconForApplication(app)
                  const tier: 'free' | 'paid' = app.is_free ? 'free' : 'paid'
                  const canOpenPlan = Boolean(billingOrgId) && !app.is_free
                  return (
                    <motion.div
                      key={app.id}
                      whileHover={{ y: -6 }}
                      transition={{ type: 'spring', stiffness: 400, damping: 28 }}
                    >
                      <DashboardModuleCard
                        catalog={catalog}
                        Icon={Icon}
                        title={displayApplicationName(app)}
                        description={displayApplicationDescription(app)}
                        badgeLabel={statusLabel[tier]}
                        badgeClass={statusBadgeClass[tier]}
                        planSummary={planSummaryFor(app)}
                        onOpen={() => handleAppClick(app)}
                        onManagePlan={canOpenPlan ? () => setPlanDialogApp(app) : undefined}
                      />
                    </motion.div>
                  )
                })}
              </div>
            )}
          </motion.div>

          {billingOrgId ? (
            <div className="mb-12">
              <OrgInboundMailboxesCard orgId={billingOrgId} canManage={canManageBilling} />
            </div>
          ) : null}

          {!loading && extraModules.length > 0 && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
            >
              <h2 className="font-display text-xl font-semibold mb-4 flex items-center gap-2">
                <ShoppingCart className="h-5 w-5 text-accent" aria-hidden />
                Więcej modułów
              </h2>
              <div className="grid sm:grid-cols-2 gap-4">
                {extraModules.map(({ mod, app }) => {
                  const Icon = mod.icon
                  return (
                    <div key={mod.slug} className="bento-card relative overflow-hidden">
                      <div className="flex items-start gap-4">
                        <div className="p-2.5 rounded-xl bg-muted shrink-0">
                          <Icon className="h-5 w-5 text-accent" aria-hidden />
                        </div>
                        <div className="flex-1 min-w-0">
                          <h3 className="font-display font-semibold mb-1">{mod.name}</h3>
                          <p className="text-sm text-muted-foreground mb-3">{mod.shortDescription ?? mod.description}</p>
                          <div className="flex flex-wrap gap-2">
                            {app && billingOrgId ? (
                              <button
                                type="button"
                                onClick={() => setPlanDialogApp(app)}
                                className="inline-flex h-9 items-center justify-center rounded-md border border-border px-4 text-sm font-medium hover:bg-muted/60"
                              >
                                Wybierz plan
                              </button>
                            ) : (
                              <Link
                                to={`/module/${mod.slug}`}
                                className="inline-flex h-9 items-center justify-center rounded-md border border-border px-4 text-sm font-medium hover:bg-muted/60"
                              >
                                Zobacz plany
                              </Link>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            </motion.div>
          )}
        </div>
      </div>

      {planDialogApp && billingOrgId && (
        <ModulePlanDialog
          appName={displayApplicationName(planDialogApp)}
          appId={planDialogApp.id}
          orgId={billingOrgId}
          canManage={canManageBilling}
          subscription={subsByAppId.get(planDialogApp.id) ?? null}
          plans={plansByAppId.get(planDialogApp.id) ?? []}
          onClose={() => setPlanDialogApp(null)}
          onChanged={applySubscriptionChange}
        />
      )}

      <Footer />
    </div>
  )
}
