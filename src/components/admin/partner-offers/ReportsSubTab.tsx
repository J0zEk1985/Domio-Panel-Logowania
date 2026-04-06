import { useMemo, useState } from 'react'
import { Download } from 'lucide-react'
import { supabase } from '../../../lib/supabase'
import { inputClass } from '../pricingAdminUtils'
import type { VendorPartnerRow } from '../partnerOffersTypes'

type DateRangeState = {
  startDate: string
  endDate: string
}

type InteractionReportRow = {
  createdAt: string
  partnerName: string
  offerTitle: string
  actionType: string
  actionValue: string
}

type OfferInteractionRaw = {
  created_at: string | null
  action_type?: string | null
  interaction_type?: string | null
  action_value?: string | null
  value?: string | null
  recorded_value?: string | null
  offer?: {
    title?: string | null
    vendor?: {
      name?: string | null
    } | null
  } | null
}

type Props = {
  vendors: VendorPartnerRow[]
}

function formatDateTimePl(iso: string): string {
  try {
    return new Intl.DateTimeFormat('pl-PL', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(iso))
  } catch {
    return '—'
  }
}

function getDefaultDateRange(): DateRangeState {
  const end = new Date()
  const start = new Date()
  start.setDate(end.getDate() - 30)
  const toInput = (date: Date) => date.toISOString().slice(0, 10)
  return {
    startDate: toInput(start),
    endDate: toInput(end),
  }
}

function csvEscape(raw: string): string {
  const value = String(raw ?? '')
  if (value.includes('"') || value.includes(',') || value.includes('\n')) {
    return `"${value.replace(/"/g, '""')}"`
  }
  return value
}

function exportToCsv(rows: InteractionReportRow[]): void {
  const headers = ['Data', 'Partner', 'Oferta', 'Akcja', 'Zarejestrowana Wartosc']
  const lines = rows.map((row) =>
    [
      formatDateTimePl(row.createdAt),
      row.partnerName,
      row.offerTitle,
      row.actionType,
      row.actionValue,
    ]
      .map(csvEscape)
      .join(','),
  )
  const csvContent = [headers.join(','), ...lines].join('\n')
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `raport_domio_${new Date().toISOString().slice(0, 10)}.csv`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

export default function ReportsSubTab({ vendors }: Props) {
  const [selectedVendor, setSelectedVendor] = useState<string>('all')
  const [dateRange, setDateRange] = useState<DateRangeState>(getDefaultDateRange)
  const [interactions, setInteractions] = useState<InteractionReportRow[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const canGenerate = useMemo(
    () => Boolean(dateRange.startDate && dateRange.endDate && dateRange.startDate <= dateRange.endDate),
    [dateRange],
  )

  const generateReport = async () => {
    setError(null)
    if (!canGenerate) {
      setError('Sprawdź zakres dat (data "Od" nie może być późniejsza niż data "Do").')
      return
    }

    setLoading(true)
    try {
      const startIso = `${dateRange.startDate}T00:00:00.000Z`
      const endIso = `${dateRange.endDate}T23:59:59.999Z`

      let query = supabase
        .from('offer_interactions')
        .select(
          'created_at, action_type, interaction_type, action_value, value, recorded_value, offer:partner_offers!inner(title, vendor_id, vendor:vendor_partners(name))',
        )
        .gte('created_at', startIso)
        .lte('created_at', endIso)
        .order('created_at', { ascending: false })

      if (selectedVendor !== 'all') {
        query = query.eq('offer.vendor_id', selectedVendor)
      }

      const { data, error: queryError } = await query
      if (queryError) {
        console.error('[ReportsSubTab] generateReport:', queryError)
        setError(queryError.message || 'Nie udało się wygenerować raportu.')
        setInteractions([])
        return
      }

      const mapped = ((data as OfferInteractionRaw[] | null) ?? []).map((row) => ({
        createdAt: row.created_at ?? '',
        partnerName: row.offer?.vendor?.name?.trim() || '—',
        offerTitle: row.offer?.title?.trim() || '—',
        actionType: row.action_type ?? row.interaction_type ?? '—',
        actionValue: row.action_value ?? row.recorded_value ?? row.value ?? '—',
      }))

      setInteractions(mapped)
    } catch (e) {
      console.error('[ReportsSubTab] generateReport (unexpected):', e)
      setError('Wystąpił nieoczekiwany błąd podczas generowania raportu.')
      setInteractions([])
    } finally {
      setLoading(false)
    }
  }

  return (
    <section aria-labelledby="reports-partner-offers-heading" className="space-y-4">
      <div>
        <h2 id="reports-partner-offers-heading" className="font-display text-xl font-semibold">
          Raporty i statystyki ofert
        </h2>
        <p className="text-sm text-muted-foreground">
          Filtruj interakcje ofert po partnerze i zakresie dat, a następnie pobierz raport CSV.
        </p>
      </div>

      <div className="bento-card p-4 space-y-4">
        <div className="grid gap-4 md:grid-cols-[1fr_auto_auto_auto_auto] md:items-end">
          <label className="block space-y-1.5 text-sm">
            <span className="text-muted-foreground">Partner</span>
            <select
              className={inputClass}
              value={selectedVendor}
              onChange={(e) => setSelectedVendor(e.target.value)}
            >
              <option value="all">Wszyscy partnerzy</option>
              {vendors.map((vendor) => (
                <option key={vendor.id} value={vendor.id}>
                  {vendor.name}
                </option>
              ))}
            </select>
          </label>

          <label className="block space-y-1.5 text-sm">
            <span className="text-muted-foreground">Od</span>
            <input
              type="date"
              className={inputClass}
              value={dateRange.startDate}
              onChange={(e) => setDateRange((prev) => ({ ...prev, startDate: e.target.value }))}
            />
          </label>

          <label className="block space-y-1.5 text-sm">
            <span className="text-muted-foreground">Do</span>
            <input
              type="date"
              className={inputClass}
              value={dateRange.endDate}
              onChange={(e) => setDateRange((prev) => ({ ...prev, endDate: e.target.value }))}
            />
          </label>

          <button
            type="button"
            onClick={() => void generateReport()}
            disabled={!canGenerate || loading}
            className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50"
          >
            {loading ? 'Generowanie…' : 'Generuj Raport'}
          </button>

          <button
            type="button"
            onClick={() => exportToCsv(interactions)}
            disabled={interactions.length === 0}
            className="inline-flex items-center justify-center gap-2 rounded-md border border-border px-4 py-2 text-sm hover:bg-muted disabled:opacity-50"
          >
            <Download className="h-4 w-4" />
            Pobierz CSV
          </button>
        </div>

        {error && (
          <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
            {error}
          </div>
        )}
      </div>

      <div className="bento-card overflow-x-auto p-0">
        <table className="w-full text-sm min-w-[64rem]">
          <thead>
            <tr className="border-b border-border/60 text-left text-muted-foreground">
              <th className="p-4 font-medium">Data i Czas</th>
              <th className="p-4 font-medium">Partner</th>
              <th className="p-4 font-medium">Oferta (Tytuł)</th>
              <th className="p-4 font-medium">Typ Akcji</th>
              <th className="p-4 font-medium">Zarejestrowana Wartość</th>
            </tr>
          </thead>
          <tbody>
            {interactions.map((row, idx) => (
              <tr key={`${row.createdAt}-${idx}`} className="border-b border-border/40 last:border-0">
                <td className="p-4 text-muted-foreground">{formatDateTimePl(row.createdAt)}</td>
                <td className="p-4">{row.partnerName}</td>
                <td className="p-4 text-muted-foreground">{row.offerTitle}</td>
                <td className="p-4 text-muted-foreground">{row.actionType}</td>
                <td className="p-4 text-muted-foreground">{row.actionValue}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {!loading && interactions.length === 0 && (
          <div className="p-8 text-center text-muted-foreground">
            Brak wyników. Ustaw filtry i kliknij „Generuj Raport”.
          </div>
        )}
      </div>
    </section>
  )
}

