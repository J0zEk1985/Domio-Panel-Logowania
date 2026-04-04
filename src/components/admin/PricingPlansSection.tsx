import { useState } from 'react'
import { Check, Edit, Plus, Tag, Trash2, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import type { Application } from '../../types/database'
import {
  formatMoneyPln,
  formatPlanLimitsSummary,
  inputClass,
  parseFeaturesFromDb,
  parseOptionalLimitInt,
} from './pricingAdminUtils'
import { applicationName, emptyPlanForm, type PricingPlanRow } from './pricingAdminTypes'

type Props = {
  applications: Application[]
  plans: PricingPlanRow[]
  onRefresh: () => Promise<void>
}

export default function PricingPlansSection({ applications, plans, onRefresh }: Props) {
  const [isAddingPlan, setIsAddingPlan] = useState(false)
  const [editingPlanId, setEditingPlanId] = useState<string | null>(null)
  const [planForm, setPlanForm] = useState(emptyPlanForm)
  const [planSaving, setPlanSaving] = useState(false)
  const [sectionError, setSectionError] = useState<string | null>(null)

  const resetPlanForm = () => {
    setPlanForm(emptyPlanForm())
    setEditingPlanId(null)
    setIsAddingPlan(false)
  }

  const openNewPlan = () => {
    setSectionError(null)
    setPlanForm(emptyPlanForm())
    setEditingPlanId(null)
    setIsAddingPlan(true)
  }

  const openEditPlan = (row: PricingPlanRow) => {
    setSectionError(null)
    setEditingPlanId(row.id)
    setIsAddingPlan(true)
    setPlanForm({
      appId: row.app_id,
      name: row.name,
      priceMonthly: String(row.price_monthly ?? ''),
      priceYearly: String(row.price_yearly ?? ''),
      featuresString: parseFeaturesFromDb(row.features).join(', '),
      maxUsers: row.max_users != null ? String(row.max_users) : '',
      maxLocations: row.max_locations != null ? String(row.max_locations) : '',
      maxStorageGb: row.max_storage_gb != null ? String(row.max_storage_gb) : '',
      hasAiFeatures: row.has_ai_features === true,
    })
  }

  const savePlan = async () => {
    setSectionError(null)
    const name = planForm.name.trim()
    if (!planForm.appId || !name) {
      setSectionError('Wybierz aplikację i podaj nazwę planu.')
      return
    }
    const monthly = Number(planForm.priceMonthly)
    const yearly = Number(planForm.priceYearly)
    if (Number.isNaN(monthly) || Number.isNaN(yearly)) {
      setSectionError('Ceny muszą być liczbami.')
      return
    }
    const features = planForm.featuresString
      .split(',')
      .map((f) => f.trim())
      .filter(Boolean)

    const maxUsersParsed = parseOptionalLimitInt(planForm.maxUsers, 'Limit użytkowników')
    if (!maxUsersParsed.ok) {
      setSectionError(maxUsersParsed.message)
      return
    }
    const maxLocationsParsed = parseOptionalLimitInt(planForm.maxLocations, 'Limit lokalizacji')
    if (!maxLocationsParsed.ok) {
      setSectionError(maxLocationsParsed.message)
      return
    }
    const maxStorageParsed = parseOptionalLimitInt(planForm.maxStorageGb, 'Limit pamięci (GB)')
    if (!maxStorageParsed.ok) {
      setSectionError(maxStorageParsed.message)
      return
    }

    setPlanSaving(true)
    try {
      const payload = {
        app_id: planForm.appId,
        name,
        price_monthly: monthly,
        price_yearly: yearly,
        features,
        max_users: maxUsersParsed.value,
        max_locations: maxLocationsParsed.value,
        max_storage_gb: maxStorageParsed.value,
        has_ai_features: planForm.hasAiFeatures,
        updated_at: new Date().toISOString(),
      }

      if (editingPlanId) {
        const { error } = await supabase.from('pricing_plans').update(payload).eq('id', editingPlanId)
        if (error) {
          console.error('[PricingPlansSection] update plan:', error)
          setSectionError(error.message || 'Nie udało się zapisać planu.')
          return
        }
      } else {
        const { error } = await supabase.from('pricing_plans').insert({
          ...payload,
          is_active: true,
        })
        if (error) {
          console.error('[PricingPlansSection] insert plan:', error)
          setSectionError(error.message || 'Nie udało się dodać planu.')
          return
        }
      }
      resetPlanForm()
      await onRefresh()
    } catch (e) {
      console.error('[PricingPlansSection] savePlan:', e)
      setSectionError('Wystąpił błąd podczas zapisu planu.')
    } finally {
      setPlanSaving(false)
    }
  }

  const togglePlanActive = async (row: PricingPlanRow) => {
    setSectionError(null)
    const { error } = await supabase
      .from('pricing_plans')
      .update({ is_active: !row.is_active, updated_at: new Date().toISOString() })
      .eq('id', row.id)
    if (error) {
      console.error('[PricingPlansSection] toggle plan:', error)
      setSectionError(error.message || 'Nie udało się zmienić statusu.')
      return
    }
    await onRefresh()
  }

  const deletePlan = async (id: string) => {
    if (!window.confirm('Czy na pewno usunąć ten plan cenowy?')) return
    setSectionError(null)
    const { error } = await supabase.from('pricing_plans').delete().eq('id', id)
    if (error) {
      console.error('[PricingPlansSection] delete plan:', error)
      setSectionError(error.message || 'Nie udało się usunąć planu.')
      return
    }
    if (editingPlanId === id) resetPlanForm()
    await onRefresh()
  }

  return (
    <section aria-labelledby="pricing-plans-heading">
      {sectionError && (
        <div className="mb-4 bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {sectionError}
        </div>
      )}

      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
        <h2 id="pricing-plans-heading" className="font-display text-xl font-semibold flex items-center gap-2">
          <Tag className="h-6 w-6 text-primary" />
          Plany cenowe
        </h2>
        {!isAddingPlan && (
          <button
            type="button"
            onClick={openNewPlan}
            className="inline-flex items-center justify-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:opacity-90"
          >
            <Plus className="h-4 w-4" />
            Dodaj nowy plan
          </button>
        )}
      </div>

      {isAddingPlan && (
        <div className="bento-card p-4 mb-6 space-y-4 border border-primary/20">
          <p className="text-sm font-medium text-foreground">{editingPlanId ? 'Edycja planu' : 'Nowy plan'}</p>
          <div className="grid sm:grid-cols-2 gap-4">
            <label className="block space-y-1.5 text-sm">
              <span className="text-muted-foreground">Aplikacja</span>
              <select
                className={inputClass}
                value={planForm.appId}
                onChange={(e) => setPlanForm((f) => ({ ...f, appId: e.target.value }))}
              >
                <option value="">— Wybierz —</option>
                {applications.map((a) => (
                  <option key={a.id} value={a.id}>
                    {a.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="block space-y-1.5 text-sm">
              <span className="text-muted-foreground">Nazwa planu</span>
              <input
                className={inputClass}
                value={planForm.name}
                onChange={(e) => setPlanForm((f) => ({ ...f, name: e.target.value }))}
                placeholder="np. Pro, Basic"
              />
            </label>
            <label className="block space-y-1.5 text-sm">
              <span className="text-muted-foreground">Cena miesięczna (zł)</span>
              <input
                type="number"
                min={0}
                step={0.01}
                className={inputClass}
                value={planForm.priceMonthly}
                onChange={(e) => setPlanForm((f) => ({ ...f, priceMonthly: e.target.value }))}
              />
            </label>
            <label className="block space-y-1.5 text-sm">
              <span className="text-muted-foreground">Cena roczna (zł)</span>
              <input
                type="number"
                min={0}
                step={0.01}
                className={inputClass}
                value={planForm.priceYearly}
                onChange={(e) => setPlanForm((f) => ({ ...f, priceYearly: e.target.value }))}
              />
            </label>
          </div>
          <div className="border-t border-border/60 pt-4 space-y-4">
            <p className="text-sm font-medium text-foreground">Limity systemowe</p>
            <p className="text-xs text-muted-foreground -mt-2">
              Pozostaw pole puste, aby oznaczyć brak limitu (nielimitowane).
            </p>
            <div className="grid sm:grid-cols-3 gap-4">
              <label className="block space-y-1.5 text-sm">
                <span className="text-muted-foreground">Limit użytkowników</span>
                <input
                  type="number"
                  min={0}
                  step={1}
                  className={inputClass}
                  value={planForm.maxUsers}
                  onChange={(e) => setPlanForm((f) => ({ ...f, maxUsers: e.target.value }))}
                  placeholder="np. 10 lub puste"
                />
              </label>
              <label className="block space-y-1.5 text-sm">
                <span className="text-muted-foreground">Limit lokalizacji / obiektów</span>
                <input
                  type="number"
                  min={0}
                  step={1}
                  className={inputClass}
                  value={planForm.maxLocations}
                  onChange={(e) => setPlanForm((f) => ({ ...f, maxLocations: e.target.value }))}
                  placeholder="np. 5 lub puste"
                />
              </label>
              <label className="block space-y-1.5 text-sm">
                <span className="text-muted-foreground">Limit pamięci (GB)</span>
                <input
                  type="number"
                  min={0}
                  step={1}
                  className={inputClass}
                  value={planForm.maxStorageGb}
                  onChange={(e) => setPlanForm((f) => ({ ...f, maxStorageGb: e.target.value }))}
                  placeholder="np. 100 lub puste"
                />
              </label>
            </div>
            <label className="flex items-start gap-3 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={planForm.hasAiFeatures}
                onChange={(e) => setPlanForm((f) => ({ ...f, hasAiFeatures: e.target.checked }))}
                className="mt-1 h-4 w-4 rounded border-input text-primary focus:ring-ring"
              />
              <span className="text-sm text-foreground">
                Dostęp do funkcji AI
                <span className="block text-xs text-muted-foreground mt-1">
                  Włącza flagę planu dla modułów korzystających z funkcji sztucznej inteligencji.
                </span>
              </span>
            </label>
          </div>
          <label className="block space-y-1.5 text-sm">
            <span className="text-muted-foreground">Funkcje (features)</span>
            <textarea
              className={`${inputClass} min-h-[88px]`}
              value={planForm.featuresString}
              onChange={(e) => setPlanForm((f) => ({ ...f, featuresString: e.target.value }))}
              placeholder="Wpisz funkcje po przecinku"
            />
          </label>
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              disabled={planSaving}
              onClick={() => void savePlan()}
              className="inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50"
            >
              <Check className="h-4 w-4" />
              Zapisz
            </button>
            <button
              type="button"
              disabled={planSaving}
              onClick={resetPlanForm}
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
              <th className="p-4 font-medium">Nazwa planu</th>
              <th className="p-4 font-medium">Aplikacja</th>
              <th className="p-4 font-medium">Cena (miesiąc / rok)</th>
              <th className="p-4 font-medium">Limity</th>
              <th className="p-4 font-medium">Status</th>
              <th className="p-4 font-medium text-right">Akcje</th>
            </tr>
          </thead>
          <tbody>
            {plans.map((row) => (
              <tr key={row.id} className="border-b border-border/40 last:border-0">
                <td className="p-4 font-medium">{row.name}</td>
                <td className="p-4 text-muted-foreground">{applicationName(row)}</td>
                <td className="p-4 text-muted-foreground">
                  {formatMoneyPln(row.price_monthly)} / {formatMoneyPln(row.price_yearly)}
                </td>
                <td className="p-4 text-muted-foreground max-w-[14rem] whitespace-normal">
                  {formatPlanLimitsSummary(row)}
                </td>
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
                    onClick={() => void togglePlanActive(row)}
                    title={row.is_active ? 'Dezaktywuj' : 'Aktywuj'}
                  >
                    <Check className="h-4 w-4" />
                  </button>
                  <button
                    type="button"
                    className="inline-flex items-center gap-1 text-primary hover:underline mr-3"
                    onClick={() => openEditPlan(row)}
                  >
                    <Edit className="h-4 w-4" />
                  </button>
                  <button
                    type="button"
                    className="inline-flex items-center gap-1 text-destructive hover:underline"
                    onClick={() => void deletePlan(row.id)}
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {plans.length === 0 && (
          <div className="p-8 text-center text-muted-foreground">
            Brak planów. Dodaj pierwszy plan lub sprawdź uprawnienia RLS.
          </div>
        )}
      </div>
    </section>
  )
}
