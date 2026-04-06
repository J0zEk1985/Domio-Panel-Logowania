import { useMemo, useState } from 'react'
import { Edit, Plus, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { inputClass } from './pricingAdminUtils'
import type { VendorPartnerRow } from './partnerOffersTypes'

type VendorFormState = {
  name: string
  serviceType: string
  contactEmail: string
  contactPhone: string
  status: string
}

const emptyVendorForm: VendorFormState = {
  name: '',
  serviceType: '',
  contactEmail: '',
  contactPhone: '',
  status: 'active',
}

type Props = {
  vendors: VendorPartnerRow[]
  loading: boolean
  onRefresh: () => Promise<void>
}

export default function VendorPartnersSubTab({ vendors, loading, onRefresh }: Props) {
  const [searchQuery, setSearchQuery] = useState('')
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingVendorId, setEditingVendorId] = useState<string | null>(null)
  const [form, setForm] = useState<VendorFormState>(emptyVendorForm)
  const [saving, setSaving] = useState(false)
  const [formError, setFormError] = useState<string | null>(null)

  const filteredVendors = useMemo(() => {
    const query = searchQuery.trim().toLowerCase()
    if (!query) return vendors
    return vendors.filter((vendor) => {
      const name = vendor.name?.toLowerCase() ?? ''
      const serviceType = vendor.service_type?.toLowerCase() ?? ''
      return name.includes(query) || serviceType.includes(query)
    })
  }, [vendors, searchQuery])

  const openCreateDialog = () => {
    setFormError(null)
    setEditingVendorId(null)
    setForm(emptyVendorForm)
    setIsDialogOpen(true)
  }

  const openEditDialog = (vendor: VendorPartnerRow) => {
    setFormError(null)
    setEditingVendorId(vendor.id)
    setForm({
      name: vendor.name ?? '',
      serviceType: vendor.service_type ?? '',
      contactEmail: vendor.contact_email ?? '',
      contactPhone: vendor.contact_phone ?? '',
      status: vendor.status ?? 'active',
    })
    setIsDialogOpen(true)
  }

  const closeDialog = () => {
    setIsDialogOpen(false)
    setEditingVendorId(null)
    setForm(emptyVendorForm)
    setFormError(null)
  }

  const saveVendor = async () => {
    setFormError(null)
    const name = form.name.trim()
    const serviceType = form.serviceType.trim()
    if (!name) {
      setFormError('Podaj nazwę firmy.')
      return
    }
    if (!serviceType) {
      setFormError('Podaj branżę lub typ usługi.')
      return
    }

    const payload = {
      name,
      service_type: serviceType,
      contact_email: form.contactEmail.trim() || null,
      contact_phone: form.contactPhone.trim() || null,
      status: form.status.trim() || null,
    }

    setSaving(true)
    try {
      const row = editingVendorId ? { id: editingVendorId, ...payload } : payload
      const { error } = await supabase.from('vendor_partners').upsert(row, { onConflict: 'id' })
      if (error) {
        console.error('[VendorPartnersSubTab] upsert vendor:', error)
        setFormError(error.message || 'Nie udało się zapisać firmy.')
        return
      }
      closeDialog()
      await onRefresh()
    } catch (e) {
      console.error('[VendorPartnersSubTab] saveVendor:', e)
      setFormError('Wystąpił błąd podczas zapisu firmy.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <section aria-labelledby="vendor-catalog-heading" className="space-y-4">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 id="vendor-catalog-heading" className="font-display text-xl font-semibold">
            Katalog firm partnerskich
          </h2>
          <p className="text-sm text-muted-foreground">Zarządzaj partnerami używanymi przy tworzeniu ofert.</p>
        </div>
        <button
          type="button"
          onClick={openCreateDialog}
          className="inline-flex items-center justify-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:opacity-90"
        >
          <Plus className="h-4 w-4" />
          Dodaj firmę
        </button>
      </div>

      <div className="bento-card overflow-x-auto p-0">
        <div className="p-4 border-b border-border/60">
          <input
            className={inputClass}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Szukaj po nazwie firmy lub branży…"
            aria-label="Szukaj firm partnerskich"
          />
        </div>
        <table className="w-full text-sm min-w-[56rem]">
          <thead>
            <tr className="border-b border-border/60 text-left text-muted-foreground">
              <th className="p-4 font-medium">Nazwa firmy</th>
              <th className="p-4 font-medium">Branża / Usługa</th>
              <th className="p-4 font-medium">Email kontaktowy</th>
              <th className="p-4 font-medium">Telefon</th>
              <th className="p-4 font-medium">Status</th>
              <th className="p-4 font-medium text-right">Akcje</th>
            </tr>
          </thead>
          <tbody>
            {!loading &&
              filteredVendors.map((vendor) => (
                <tr key={vendor.id} className="border-b border-border/40 last:border-0">
                  <td className="p-4 font-medium">{vendor.name}</td>
                  <td className="p-4 text-muted-foreground">{vendor.service_type ?? '—'}</td>
                  <td className="p-4 text-muted-foreground">{vendor.contact_email ?? '—'}</td>
                  <td className="p-4 text-muted-foreground">{vendor.contact_phone ?? '—'}</td>
                  <td className="p-4 text-muted-foreground">
                    {vendor.status === 'active'
                      ? 'Aktywna'
                      : vendor.status === 'inactive'
                        ? 'Nieaktywna'
                        : vendor.status ?? '—'}
                  </td>
                  <td className="p-4 text-right">
                    <button
                      type="button"
                      className="inline-flex items-center gap-1 text-primary hover:underline"
                      onClick={() => openEditDialog(vendor)}
                    >
                      <Edit className="h-4 w-4" />
                      Edytuj
                    </button>
                  </td>
                </tr>
              ))}
          </tbody>
        </table>
        {loading && <div className="p-8 text-center text-muted-foreground">Ładowanie firm…</div>}
        {!loading && vendors.length === 0 && (
          <div className="p-8 text-center text-muted-foreground">Brak firm partnerskich. Dodaj pierwszą pozycję.</div>
        )}
        {!loading && vendors.length > 0 && filteredVendors.length === 0 && (
          <div className="p-8 text-center text-muted-foreground">Brak firm spełniających kryteria wyszukiwania.</div>
        )}
      </div>

      {isDialogOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 p-4 sm:p-6 overflow-y-auto">
          <div className="mx-auto w-full max-w-xl rounded-xl bg-background border border-border shadow-xl">
            <div className="flex items-center justify-between px-5 py-4 border-b border-border">
              <h3 className="font-display text-lg font-semibold">
                {editingVendorId ? 'Edycja firmy partnerskiej' : 'Nowa firma partnerska'}
              </h3>
              <button type="button" onClick={closeDialog} className="text-muted-foreground hover:text-foreground">
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="p-5 space-y-4">
              {formError && (
                <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
                  {formError}
                </div>
              )}

              <label className="block space-y-1.5 text-sm">
                <span className="text-muted-foreground">Nazwa firmy</span>
                <input
                  className={inputClass}
                  value={form.name}
                  onChange={(e) => setForm((prev) => ({ ...prev, name: e.target.value }))}
                />
              </label>

              <label className="block space-y-1.5 text-sm">
                <span className="text-muted-foreground">Branża / Typ usługi</span>
                <input
                  className={inputClass}
                  value={form.serviceType}
                  onChange={(e) => setForm((prev) => ({ ...prev, serviceType: e.target.value }))}
                  placeholder="np. Hydraulika, Sprzątanie, Internet, Inne"
                />
              </label>

              <div className="grid sm:grid-cols-2 gap-4">
                <label className="block space-y-1.5 text-sm">
                  <span className="text-muted-foreground">Email kontaktowy</span>
                  <input
                    className={inputClass}
                    type="email"
                    value={form.contactEmail}
                    onChange={(e) => setForm((prev) => ({ ...prev, contactEmail: e.target.value }))}
                  />
                </label>

                <label className="block space-y-1.5 text-sm">
                  <span className="text-muted-foreground">Telefon kontaktowy</span>
                  <input
                    className={inputClass}
                    value={form.contactPhone}
                    onChange={(e) => setForm((prev) => ({ ...prev, contactPhone: e.target.value }))}
                  />
                </label>
              </div>

              <label className="block space-y-1.5 text-sm">
                <span className="text-muted-foreground">Status</span>
                <select
                  className={inputClass}
                  value={form.status}
                  onChange={(e) => setForm((prev) => ({ ...prev, status: e.target.value }))}
                >
                  <option value="active">Aktywna</option>
                  <option value="inactive">Nieaktywna</option>
                </select>
              </label>
            </div>

            <div className="px-5 py-4 border-t border-border flex flex-wrap justify-end gap-2">
              <button
                type="button"
                onClick={closeDialog}
                disabled={saving}
                className="rounded-md border border-border px-4 py-2 text-sm hover:bg-muted disabled:opacity-50"
              >
                Anuluj
              </button>
              <button
                type="button"
                onClick={() => void saveVendor()}
                disabled={saving}
                className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50"
              >
                {saving ? 'Zapisywanie…' : 'Zapisz'}
              </button>
            </div>
          </div>
        </div>
      )}
    </section>
  )
}

