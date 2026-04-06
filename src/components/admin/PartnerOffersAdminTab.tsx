import { useCallback, useEffect, useMemo, useState } from 'react'
import { Edit, Plus, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { inputClass } from './pricingAdminUtils'

type BillingModel = 'subscription' | 'commission'
type ActionType = 'url' | 'code' | 'lead'

type PartnerOfferRow = {
  id: string
  title: string
  description: string | null
  vendor_id: string
  billing_model: BillingModel
  action_type: ActionType
  action_value: string | null
  is_active: boolean
  target_locations: string[] | null
}

type VendorPartnerRow = {
  id: string
  name: string
}

type OfferFormState = {
  title: string
  description: string
  vendorId: string
  billingModel: BillingModel
  actionType: ActionType
  actionValue: string
  isActive: boolean
  targetLocations: string
}

const emptyForm: OfferFormState = {
  title: '',
  description: '',
  vendorId: '',
  billingModel: 'subscription',
  actionType: 'url',
  actionValue: '',
  isActive: true,
  targetLocations: '',
}

const uuidRegex =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

const billingModelLabel: Record<BillingModel, string> = {
  subscription: 'Abonament',
  commission: 'Prowizja',
}

const actionTypeLabel: Record<ActionType, string> = {
  url: 'Link',
  code: 'Kod',
  lead: 'Lead',
}

function parseTargetLocations(raw: string): { ok: true; value: string[] | null } | { ok: false; message: string } {
  const normalized = raw
    .split(/[,\s]+/)
    .map((part) => part.trim())
    .filter(Boolean)
  if (normalized.length === 0) return { ok: true, value: null }
  const invalid = normalized.find((id) => !uuidRegex.test(id))
  if (invalid) {
    return { ok: false, message: `Nieprawidłowy UUID w Target ID Lokacji: ${invalid}` }
  }
  return { ok: true, value: normalized }
}

export default function PartnerOffersAdminTab() {
  const [offers, setOffers] = useState<PartnerOfferRow[]>([])
  const [partners, setPartners] = useState<VendorPartnerRow[]>([])
  const [interactionsCount, setInteractionsCount] = useState<number>(0)
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)

  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingOfferId, setEditingOfferId] = useState<string | null>(null)
  const [form, setForm] = useState<OfferFormState>(emptyForm)
  const [saving, setSaving] = useState(false)
  const [formError, setFormError] = useState<string | null>(null)

  const partnerNameById = useMemo(
    () => Object.fromEntries(partners.map((partner) => [partner.id, partner.name])),
    [partners],
  )

  const loadAll = useCallback(async () => {
    setLoadError(null)
    try {
      const [offersRes, partnersRes, interactionsRes] = await Promise.all([
        supabase
          .from('partner_offers')
          .select('id, title, description, vendor_id, billing_model, action_type, action_value, is_active, target_locations')
          .order('title'),
        supabase.from('vendor_partners').select('id, name').order('name'),
        supabase.from('offer_interactions').select('*', { count: 'exact', head: true }),
      ])

      if (offersRes.error) {
        console.error('[PartnerOffersAdminTab] partner_offers:', offersRes.error)
        setLoadError('Nie udało się pobrać ofert partnerskich.')
        setOffers([])
      } else {
        setOffers((offersRes.data as PartnerOfferRow[] | null) ?? [])
      }

      if (partnersRes.error) {
        console.error('[PartnerOffersAdminTab] vendor_partners:', partnersRes.error)
        setLoadError((prev) => prev ?? 'Nie udało się pobrać listy partnerów.')
        setPartners([])
      } else {
        setPartners((partnersRes.data as VendorPartnerRow[] | null) ?? [])
      }

      if (interactionsRes.error) {
        console.error('[PartnerOffersAdminTab] offer_interactions count:', interactionsRes.error)
        setLoadError((prev) => prev ?? 'Nie udało się pobrać metryk interakcji.')
        setInteractionsCount(0)
      } else {
        setInteractionsCount(interactionsRes.count ?? 0)
      }
    } catch (e) {
      console.error('[PartnerOffersAdminTab] loadAll:', e)
      setLoadError('Wystąpił nieoczekiwany błąd podczas ładowania danych ofert.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadAll()
  }, [loadAll])

  const openCreateDialog = () => {
    setFormError(null)
    setEditingOfferId(null)
    setForm(emptyForm)
    setIsDialogOpen(true)
  }

  const openEditDialog = (row: PartnerOfferRow) => {
    setFormError(null)
    setEditingOfferId(row.id)
    setForm({
      title: row.title ?? '',
      description: row.description ?? '',
      vendorId: row.vendor_id ?? '',
      billingModel: row.billing_model,
      actionType: row.action_type,
      actionValue: row.action_value ?? '',
      isActive: row.is_active,
      targetLocations: row.target_locations?.join(', ') ?? '',
    })
    setIsDialogOpen(true)
  }

  const closeDialog = () => {
    setIsDialogOpen(false)
    setEditingOfferId(null)
    setForm(emptyForm)
    setFormError(null)
  }

  const saveOffer = async () => {
    setFormError(null)

    const title = form.title.trim()
    if (!title) {
      setFormError('Podaj tytuł oferty.')
      return
    }
    if (!form.vendorId) {
      setFormError('Wybierz partnera.')
      return
    }

    const targetLocationsParsed = parseTargetLocations(form.targetLocations)
    if (!targetLocationsParsed.ok) {
      setFormError(targetLocationsParsed.message)
      return
    }

    const payload = {
      title,
      description: form.description.trim() || null,
      vendor_id: form.vendorId,
      billing_model: form.billingModel,
      action_type: form.actionType,
      action_value: form.actionValue.trim() || null,
      is_active: form.isActive,
      target_locations: targetLocationsParsed.value,
    }

    setSaving(true)
    try {
      const row = editingOfferId ? { id: editingOfferId, ...payload } : payload
      const { error } = await supabase.from('partner_offers').upsert(row, { onConflict: 'id' })
      if (error) {
        console.error('[PartnerOffersAdminTab] upsert offer:', error)
        setFormError(error.message || 'Nie udało się zapisać oferty.')
        return
      }
      closeDialog()
      await loadAll()
    } catch (e) {
      console.error('[PartnerOffersAdminTab] saveOffer:', e)
      setFormError('Wystąpił błąd podczas zapisu oferty.')
    } finally {
      setSaving(false)
    }
  }

  const activeOffers = useMemo(() => offers.filter((offer) => offer.is_active).length, [offers])

  return (
    <div className="space-y-6">
      {loadError && (
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {loadError}
        </div>
      )}

      <div className="grid sm:grid-cols-3 gap-4">
        <div className="bento-card">
          <p className="text-sm text-muted-foreground mb-1">Aktywne oferty</p>
          <p className="font-display text-2xl font-bold">{loading ? '…' : activeOffers}</p>
        </div>
        <div className="bento-card">
          <p className="text-sm text-muted-foreground mb-1">Firmy partnerskie</p>
          <p className="font-display text-2xl font-bold">{loading ? '…' : partners.length}</p>
        </div>
        <div className="bento-card">
          <p className="text-sm text-muted-foreground mb-1">Liczba interakcji</p>
          <p className="font-display text-2xl font-bold">{loading ? '…' : interactionsCount.toLocaleString('pl-PL')}</p>
        </div>
      </div>

      <section aria-labelledby="partner-offers-heading">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-4">
          <div>
            <h2 id="partner-offers-heading" className="font-display text-xl font-semibold">
              Zarządzanie ofertami partnerów
            </h2>
            <p className="text-sm text-muted-foreground">Dodawaj i edytuj oferty dostępne dla użytkowników platformy.</p>
          </div>
          <button
            type="button"
            onClick={openCreateDialog}
            className="inline-flex items-center justify-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:opacity-90"
          >
            <Plus className="h-4 w-4" />
            Dodaj ofertę
          </button>
        </div>

        <div className="bento-card overflow-x-auto p-0">
          <table className="w-full text-sm min-w-[54rem]">
            <thead>
              <tr className="border-b border-border/60 text-left text-muted-foreground">
                <th className="p-4 font-medium">Tytuł</th>
                <th className="p-4 font-medium">Partner</th>
                <th className="p-4 font-medium">Typ akcji</th>
                <th className="p-4 font-medium">Model rozliczeń</th>
                <th className="p-4 font-medium">Status</th>
                <th className="p-4 font-medium text-right">Akcje</th>
              </tr>
            </thead>
            <tbody>
              {!loading &&
                offers.map((row) => (
                  <tr key={row.id} className="border-b border-border/40 last:border-0">
                    <td className="p-4 font-medium">{row.title}</td>
                    <td className="p-4 text-muted-foreground">{partnerNameById[row.vendor_id] ?? 'Nieznany partner'}</td>
                    <td className="p-4 text-muted-foreground">{actionTypeLabel[row.action_type]}</td>
                    <td className="p-4 text-muted-foreground">{billingModelLabel[row.billing_model]}</td>
                    <td className="p-4">
                      <span
                        className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                          row.is_active ? 'bg-primary/10 text-primary' : 'bg-muted text-muted-foreground'
                        }`}
                      >
                        {row.is_active ? 'Aktywna' : 'Nieaktywna'}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      <button
                        type="button"
                        className="inline-flex items-center gap-1 text-primary hover:underline"
                        onClick={() => openEditDialog(row)}
                      >
                        <Edit className="h-4 w-4" />
                        Edytuj
                      </button>
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
          {loading && <div className="p-8 text-center text-muted-foreground">Ładowanie ofert…</div>}
          {!loading && offers.length === 0 && (
            <div className="p-8 text-center text-muted-foreground">Brak ofert. Dodaj pierwszą ofertę partnerską.</div>
          )}
        </div>
      </section>

      {isDialogOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 p-4 sm:p-6 overflow-y-auto">
          <div className="mx-auto w-full max-w-2xl rounded-xl bg-background border border-border shadow-xl">
            <div className="flex items-center justify-between px-5 py-4 border-b border-border">
              <h3 className="font-display text-lg font-semibold">
                {editingOfferId ? 'Edycja oferty partnerskiej' : 'Nowa oferta partnerska'}
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
                <span className="text-muted-foreground">Tytuł oferty</span>
                <input
                  className={inputClass}
                  value={form.title}
                  onChange={(e) => setForm((prev) => ({ ...prev, title: e.target.value }))}
                />
              </label>

              <label className="block space-y-1.5 text-sm">
                <span className="text-muted-foreground">Opis</span>
                <textarea
                  className={`${inputClass} min-h-[90px]`}
                  value={form.description}
                  onChange={(e) => setForm((prev) => ({ ...prev, description: e.target.value }))}
                />
              </label>

              <div className="grid sm:grid-cols-2 gap-4">
                <label className="block space-y-1.5 text-sm">
                  <span className="text-muted-foreground">Partner (Usługodawca)</span>
                  <select
                    className={inputClass}
                    value={form.vendorId}
                    onChange={(e) => setForm((prev) => ({ ...prev, vendorId: e.target.value }))}
                  >
                    <option value="">Wybierz partnera</option>
                    {partners.map((partner) => (
                      <option key={partner.id} value={partner.id}>
                        {partner.name}
                      </option>
                    ))}
                  </select>
                </label>

                <label className="block space-y-1.5 text-sm">
                  <span className="text-muted-foreground">Model rozliczeń</span>
                  <select
                    className={inputClass}
                    value={form.billingModel}
                    onChange={(e) => setForm((prev) => ({ ...prev, billingModel: e.target.value as BillingModel }))}
                  >
                    <option value="subscription">Abonament</option>
                    <option value="commission">Prowizja</option>
                  </select>
                </label>

                <label className="block space-y-1.5 text-sm">
                  <span className="text-muted-foreground">Typ akcji</span>
                  <select
                    className={inputClass}
                    value={form.actionType}
                    onChange={(e) => setForm((prev) => ({ ...prev, actionType: e.target.value as ActionType }))}
                  >
                    <option value="url">Link zewnętrzny</option>
                    <option value="code">Kod rabatowy</option>
                    <option value="lead">Formularz kontaktowy</option>
                  </select>
                </label>

                <label className="block space-y-1.5 text-sm">
                  <span className="text-muted-foreground">Wartość akcji</span>
                  <input
                    className={inputClass}
                    value={form.actionValue}
                    onChange={(e) => setForm((prev) => ({ ...prev, actionValue: e.target.value }))}
                    placeholder={form.actionType === 'code' ? 'np. START20' : 'https://...'}
                  />
                  <span className="text-xs text-muted-foreground">
                    Wpisz kod rabatowy (np. START20) lub wklej adres URL, jeśli wybrałeś Link.
                  </span>
                </label>
              </div>

              <label className="block space-y-1.5 text-sm">
                <span className="text-muted-foreground">Target ID Lokacji (opcjonalnie)</span>
                <input
                  className={inputClass}
                  value={form.targetLocations}
                  onChange={(e) => setForm((prev) => ({ ...prev, targetLocations: e.target.value }))}
                  placeholder="UUID lub kilka UUID rozdzielonych przecinkiem"
                />
              </label>

              <label className="inline-flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  checked={form.isActive}
                  onChange={(e) => setForm((prev) => ({ ...prev, isActive: e.target.checked }))}
                />
                <span>Aktywna</span>
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
                onClick={() => void saveOffer()}
                disabled={saving}
                className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50"
              >
                {saving ? 'Zapisywanie…' : 'Zapisz'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
