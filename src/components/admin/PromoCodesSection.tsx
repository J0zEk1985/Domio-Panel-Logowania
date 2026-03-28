import { useState } from 'react'
import { Check, Edit, Plus, Trash2, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { formatDatePl, formatMoneyPln, inputClass } from './pricingAdminUtils'
import { emptyPromoForm, type PromoCodeRow } from './pricingAdminTypes'

type Props = {
  promoCodes: PromoCodeRow[]
  onRefresh: () => Promise<void>
}

export default function PromoCodesSection({ promoCodes, onRefresh }: Props) {
  const [isAddingPromo, setIsAddingPromo] = useState(false)
  const [editingPromoId, setEditingPromoId] = useState<string | null>(null)
  const [promoForm, setPromoForm] = useState(emptyPromoForm)
  const [promoSaving, setPromoSaving] = useState(false)
  const [sectionError, setSectionError] = useState<string | null>(null)

  const resetPromoForm = () => {
    setPromoForm(emptyPromoForm())
    setEditingPromoId(null)
    setIsAddingPromo(false)
  }

  const openNewPromo = () => {
    setSectionError(null)
    setPromoForm(emptyPromoForm())
    setEditingPromoId(null)
    setIsAddingPromo(true)
  }

  const openEditPromo = (row: PromoCodeRow) => {
    setSectionError(null)
    setEditingPromoId(row.id)
    setIsAddingPromo(true)
    setPromoForm({
      code: row.code,
      discountPercent: row.discount_percent != null ? String(row.discount_percent) : '',
      discountAmount: row.discount_amount != null ? String(row.discount_amount) : '',
      maxUses: row.max_uses != null ? String(row.max_uses) : '',
      validUntil: row.valid_until ? row.valid_until.slice(0, 10) : '',
    })
  }

  const savePromo = async () => {
    setSectionError(null)
    const code = promoForm.code.trim().toUpperCase()
    if (!code) {
      setSectionError('Podaj kod promocyjny.')
      return
    }
    const dp = promoForm.discountPercent.trim()
    const da = promoForm.discountAmount.trim()
    const discountPercent = dp === '' ? null : Number(dp)
    const discountAmount = da === '' ? null : Number(da)
    if ((dp !== '' && Number.isNaN(discountPercent)) || (da !== '' && Number.isNaN(discountAmount))) {
      setSectionError('Zniżki muszą być liczbami.')
      return
    }
    if (discountPercent == null && discountAmount == null) {
      setSectionError('Podaj zniżkę procentową lub kwotową.')
      return
    }

    const mu = promoForm.maxUses.trim()
    let maxUses: number | null = null
    if (mu !== '') {
      const parsed = parseInt(mu, 10)
      if (Number.isNaN(parsed) || parsed < 0) {
        setSectionError('Limit użyć musi być nieujemną liczbą całkowitą.')
        return
      }
      maxUses = parsed
    }

    const validUntil = promoForm.validUntil.trim() || null

    setPromoSaving(true)
    try {
      const base = {
        code,
        discount_percent: discountPercent,
        discount_amount: discountAmount,
        max_uses: maxUses,
        valid_until: validUntil,
      }

      if (editingPromoId) {
        const { error } = await supabase.from('promo_codes').update(base).eq('id', editingPromoId)
        if (error) {
          console.error('[PromoCodesSection] update promo:', error)
          setSectionError(error.message || 'Nie udało się zapisać kodu.')
          return
        }
      } else {
        const { error } = await supabase.from('promo_codes').insert({
          ...base,
          is_active: true,
          used_count: 0,
        })
        if (error) {
          console.error('[PromoCodesSection] insert promo:', error)
          setSectionError(error.message || 'Nie udało się dodać kodu.')
          return
        }
      }
      resetPromoForm()
      await onRefresh()
    } catch (e) {
      console.error('[PromoCodesSection] savePromo:', e)
      setSectionError('Wystąpił błąd podczas zapisu kodu.')
    } finally {
      setPromoSaving(false)
    }
  }

  const togglePromoActive = async (row: PromoCodeRow) => {
    setSectionError(null)
    const { error } = await supabase.from('promo_codes').update({ is_active: !row.is_active }).eq('id', row.id)
    if (error) {
      console.error('[PromoCodesSection] toggle promo:', error)
      setSectionError(error.message || 'Nie udało się zmienić statusu.')
      return
    }
    await onRefresh()
  }

  const deletePromo = async (id: string) => {
    if (!window.confirm('Czy na pewno usunąć ten kod promocyjny?')) return
    setSectionError(null)
    const { error } = await supabase.from('promo_codes').delete().eq('id', id)
    if (error) {
      console.error('[PromoCodesSection] delete promo:', error)
      setSectionError(error.message || 'Nie udało się usunąć kodu.')
      return
    }
    if (editingPromoId === id) resetPromoForm()
    await onRefresh()
  }

  return (
    <section aria-labelledby="promo-codes-heading">
      {sectionError && (
        <div className="mb-4 bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {sectionError}
        </div>
      )}

      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
        <h2 id="promo-codes-heading" className="font-display text-xl font-semibold">
          Kody promocyjne
        </h2>
        {!isAddingPromo && (
          <button
            type="button"
            onClick={openNewPromo}
            className="inline-flex items-center justify-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:opacity-90"
          >
            <Plus className="h-4 w-4" />
            Dodaj kod
          </button>
        )}
      </div>

      {isAddingPromo && (
        <div className="bento-card p-4 mb-6 space-y-4 border border-primary/20">
          <p className="text-sm font-medium text-foreground">{editingPromoId ? 'Edycja kodu' : 'Nowy kod'}</p>
          <div className="grid sm:grid-cols-2 gap-4">
            <label className="block space-y-1.5 text-sm sm:col-span-2">
              <span className="text-muted-foreground">Kod</span>
              <input
                className={inputClass}
                value={promoForm.code}
                onChange={(e) => setPromoForm((f) => ({ ...f, code: e.target.value }))}
                placeholder="np. START2026"
              />
            </label>
            <label className="block space-y-1.5 text-sm">
              <span className="text-muted-foreground">Zniżka (%)</span>
              <input
                type="number"
                min={0}
                max={100}
                step={0.01}
                className={inputClass}
                value={promoForm.discountPercent}
                onChange={(e) => setPromoForm((f) => ({ ...f, discountPercent: e.target.value }))}
              />
            </label>
            <label className="block space-y-1.5 text-sm">
              <span className="text-muted-foreground">Zniżka (kwota zł)</span>
              <input
                type="number"
                min={0}
                step={0.01}
                className={inputClass}
                value={promoForm.discountAmount}
                onChange={(e) => setPromoForm((f) => ({ ...f, discountAmount: e.target.value }))}
              />
            </label>
            <label className="block space-y-1.5 text-sm">
              <span className="text-muted-foreground">Limit użyć (puste = bez limitu)</span>
              <input
                type="number"
                min={0}
                step={1}
                className={inputClass}
                value={promoForm.maxUses}
                onChange={(e) => setPromoForm((f) => ({ ...f, maxUses: e.target.value }))}
              />
            </label>
            <label className="block space-y-1.5 text-sm">
              <span className="text-muted-foreground">Ważny do</span>
              <input
                type="date"
                className={inputClass}
                value={promoForm.validUntil}
                onChange={(e) => setPromoForm((f) => ({ ...f, validUntil: e.target.value }))}
              />
            </label>
          </div>
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              disabled={promoSaving}
              onClick={() => void savePromo()}
              className="inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50"
            >
              <Check className="h-4 w-4" />
              Zapisz
            </button>
            <button
              type="button"
              disabled={promoSaving}
              onClick={resetPromoForm}
              className="inline-flex items-center gap-2 rounded-md border border-border px-4 py-2 text-sm hover:bg-muted"
            >
              <X className="h-4 w-4" />
              Anuluj
            </button>
          </div>
        </div>
      )}

      <div className="bento-card overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border/60 text-left text-muted-foreground">
              <th className="p-4 font-medium">Kod</th>
              <th className="p-4 font-medium">Zniżka (%)</th>
              <th className="p-4 font-medium">Zniżka (kwota)</th>
              <th className="p-4 font-medium">Limit użyć</th>
              <th className="p-4 font-medium">Wykorzystano</th>
              <th className="p-4 font-medium">Ważny do</th>
              <th className="p-4 font-medium">Status</th>
              <th className="p-4 font-medium text-right">Akcje</th>
            </tr>
          </thead>
          <tbody>
            {promoCodes.map((row) => (
              <tr key={row.id} className="border-b border-border/40 last:border-0">
                <td className="p-4 font-mono font-medium">{row.code}</td>
                <td className="p-4 text-muted-foreground">
                  {row.discount_percent != null ? `${row.discount_percent}%` : '—'}
                </td>
                <td className="p-4 text-muted-foreground">{formatMoneyPln(row.discount_amount)}</td>
                <td className="p-4 text-muted-foreground">{row.max_uses ?? '∞'}</td>
                <td className="p-4 text-muted-foreground">{row.used_count}</td>
                <td className="p-4 text-muted-foreground">{formatDatePl(row.valid_until ?? undefined)}</td>
                <td className="p-4">
                  <span
                    className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                      row.is_active ? 'bg-primary/10 text-primary' : 'bg-muted text-muted-foreground'
                    }`}
                  >
                    {row.is_active ? 'Aktywny' : 'Nieaktywny'}
                  </span>
                </td>
                <td className="p-4 text-right whitespace-nowrap">
                  <button
                    type="button"
                    className="inline-flex items-center gap-1 text-primary hover:underline mr-3"
                    onClick={() => void togglePromoActive(row)}
                    title={row.is_active ? 'Dezaktywuj' : 'Aktywuj'}
                  >
                    <Check className="h-4 w-4" />
                  </button>
                  <button
                    type="button"
                    className="inline-flex items-center gap-1 text-primary hover:underline mr-3"
                    onClick={() => openEditPromo(row)}
                  >
                    <Edit className="h-4 w-4" />
                  </button>
                  <button
                    type="button"
                    className="inline-flex items-center gap-1 text-destructive hover:underline"
                    onClick={() => void deletePromo(row.id)}
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {promoCodes.length === 0 && (
          <div className="p-8 text-center text-muted-foreground">Brak kodów. Dodaj pierwszy kod promocyjny.</div>
        )}
      </div>
    </section>
  )
}
