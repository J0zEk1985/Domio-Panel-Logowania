import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { Navbar } from '../components/landing/Navbar'
import { Footer } from '../components/landing/Footer'
import { OrgCompanyProfileForm } from '../components/dashboard/OrgCompanyProfileForm'
import { useDashboardApps } from '../hooks/useDashboardApps'

export default function CompanySettingsPage() {
  const { loading, error, billingOrgId, canManageOrgProfile } = useDashboardApps()

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <Navbar />
      <div className="flex-1 pt-24 pb-16 px-4">
        <div className="container mx-auto max-w-3xl space-y-6">
          <Link
            to="/dashboard"
            className="inline-flex items-center gap-2 text-sm font-medium text-primary hover:underline"
          >
            <ArrowLeft className="h-4 w-4" aria-hidden />
            Wróć do panelu
          </Link>
          <div>
            <h1 className="font-display text-3xl font-bold mb-2">Dane firmy</h1>
            <p className="text-muted-foreground">
              Nazwa i identyfikator firmy pojawiają się w aliasie e-mail zgłoszeń (np.{' '}
              <code className="bg-muted px-1 py-0.5 rounded text-sm">usterki+serwis-nazwafirmy@domio.com.pl</code>
              ).
            </p>
          </div>
          {loading ? <p className="text-muted-foreground">Ładowanie…</p> : null}
          {error ? (
            <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl">
              {error}
            </div>
          ) : null}
          {!loading && !billingOrgId ? (
            <p className="text-muted-foreground">Nie znaleziono firmy przypisanej do tego konta.</p>
          ) : null}
          {billingOrgId ? (
            <section className="rounded-2xl border border-border bg-card p-5">
              <OrgCompanyProfileForm organizationId={billingOrgId} canManage={canManageOrgProfile} />
            </section>
          ) : null}
        </div>
      </div>
      <Footer />
    </div>
  )
}
