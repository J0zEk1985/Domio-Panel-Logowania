import { useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { toast } from 'sonner'
import { Navbar } from '../components/landing/Navbar'
import { Footer } from '../components/landing/Footer'
import { OrgCompanyProfileForm } from '../components/dashboard/OrgCompanyProfileForm'
import { useDashboardApps } from '../hooks/useDashboardApps'
import { ensureMyBillingOrganization } from '../lib/orgBilling'

const fieldClass =
  'w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-60'

function CreateCompanyForm({ onCreated }: { onCreated: () => Promise<void> }) {
  const [name, setName] = useState('')
  const [nip, setNip] = useState('')
  const [address, setAddress] = useState('')
  const [city, setCity] = useState('')
  const [postalCode, setPostalCode] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const save = async () => {
    setError(null)
    const trimmed = name.trim()
    if (!trimmed) {
      setError('Nazwa firmy jest wymagana.')
      return
    }
    const nipDigits = nip.replace(/\s+/g, '')
    if (nipDigits && !/^\d{10}$/.test(nipDigits)) {
      setError('NIP musi składać się z 10 cyfr.')
      return
    }
    setSaving(true)
    try {
      await ensureMyBillingOrganization({
        name: trimmed,
        nip: nipDigits || null,
        address,
        city,
        postalCode,
      })
      toast.success('Zapisano dane firmy.')
      await onCreated()
    } catch (e) {
      console.error('[CompanySettingsPage] create:', e)
      setError(e instanceof Error ? e.message : 'Nie udało się zapisać danych firmy.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="space-y-4">
      {error ? (
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {error}
        </div>
      ) : null}
      <p className="text-sm text-muted-foreground">
        Możesz uzupełnić dane teraz albo przy pierwszym zakupie planu. Nazwa firmy jest wymagana.
      </p>
      <div className="grid sm:grid-cols-2 gap-4">
        <div className="space-y-1.5 sm:col-span-2">
          <label className="block text-sm text-muted-foreground" htmlFor="new-org-name">
            Nazwa firmy
          </label>
          <input id="new-org-name" className={fieldClass} value={name} disabled={saving} onChange={(e) => setName(e.target.value)} />
        </div>
        <div className="space-y-1.5">
          <label className="block text-sm text-muted-foreground" htmlFor="new-org-nip">
            NIP
          </label>
          <input id="new-org-nip" className={fieldClass} value={nip} disabled={saving} onChange={(e) => setNip(e.target.value)} />
        </div>
        <div className="space-y-1.5">
          <label className="block text-sm text-muted-foreground" htmlFor="new-org-city">
            Miasto
          </label>
          <input id="new-org-city" className={fieldClass} value={city} disabled={saving} onChange={(e) => setCity(e.target.value)} />
        </div>
        <div className="space-y-1.5 sm:col-span-2">
          <label className="block text-sm text-muted-foreground" htmlFor="new-org-address">
            Adres
          </label>
          <input
            id="new-org-address"
            className={fieldClass}
            value={address}
            disabled={saving}
            onChange={(e) => setAddress(e.target.value)}
          />
        </div>
        <div className="space-y-1.5">
          <label className="block text-sm text-muted-foreground" htmlFor="new-org-postal">
            Kod pocztowy
          </label>
          <input
            id="new-org-postal"
            className={fieldClass}
            value={postalCode}
            disabled={saving}
            onChange={(e) => setPostalCode(e.target.value)}
          />
        </div>
      </div>
      <button
        type="button"
        disabled={saving}
        onClick={() => void save()}
        className="inline-flex items-center justify-center rounded-md bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50"
      >
        {saving ? 'Zapisywanie…' : 'Zapisz dane firmy'}
      </button>
    </div>
  )
}

export default function CompanySettingsPage() {
  const { loading, error, billingOrgId, canManageOrgProfile, reload } = useDashboardApps()

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
            <section className="rounded-2xl border border-border bg-card p-5">
              <CreateCompanyForm onCreated={reload} />
            </section>
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
