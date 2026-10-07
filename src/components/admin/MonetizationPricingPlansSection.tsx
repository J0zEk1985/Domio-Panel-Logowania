/**
 * MonetizationPricingPlansSection
 * 
 * Service Owner / SuperAdmin panel for managing module pricing plans
 * Handles unit-based (home) and flat-rate (developer_warranty) plans.
 * Other applications are priced in Cennik i Promocje.
 */

import { useState, useEffect } from 'react'
import { Plus, Edit, Trash2, Check, X, DollarSign } from 'lucide-react'
import { toast } from 'sonner'
import { usePricingPlans } from '../../hooks/useMonetization'
import type {
  PricingPlan,
  CreatePricingPlanInput,
  AppModule,
} from '../../types/monetization'
import { MODULE_DISPLAY_NAMES } from '../../types/monetization'

const inputClass =
  'w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring'

interface PlanFormData {
  module: AppModule | ''
  display_name: string
  description: string
  is_global: boolean
  is_unit_based: boolean
  price_per_unit: string
  min_price: string
  price_monthly: string
  price_yearly: string
  features_string: string
  terms_conditions: string
}

const emptyForm = (): PlanFormData => ({
  module: '',
  display_name: '',
  description: '',
  is_global: false,
  is_unit_based: false,
  price_per_unit: '',
  min_price: '',
  price_monthly: '',
  price_yearly: '',
  features_string: '',
  terms_conditions: '',
})

/** Only Home and developer warranty are priced here. Other apps use Cennik i Promocje. */
const MODULE_OPTIONS: { value: AppModule; label: string }[] = [
  { value: 'home', label: 'DOMIO Home' },
  { value: 'developer_warranty', label: 'Usterki Deweloperskie' },
]

const MODULE_PLAN_MODULES = new Set<AppModule>(MODULE_OPTIONS.map((opt) => opt.value))

export default function MonetizationPricingPlansSection() {
  const { plans, loading, error, fetchPlans, createPlan, updatePlan, deletePlan } = usePricingPlans()

  const [isAddingPlan, setIsAddingPlan] = useState(false)
  const [editingPlanId, setEditingPlanId] = useState<string | null>(null)
  const [planForm, setPlanForm] = useState<PlanFormData>(emptyForm())
  const [planSaving, setPlanSaving] = useState(false)
  const [formError, setFormError] = useState<string | null>(null)

  useEffect(() => {
    void fetchPlans()
  }, [fetchPlans])

  const resetForm = () => {
    setPlanForm(emptyForm())
    setEditingPlanId(null)
    setIsAddingPlan(false)
    setFormError(null)
  }

  const openNewPlan = () => {
    resetForm()
    setIsAddingPlan(true)
  }

  const openEditPlan = (plan: PricingPlan) => {
    setEditingPlanId(plan.id)
    setIsAddingPlan(true)
    setFormError(null)
    setPlanForm({
      module: plan.module,
      display_name: plan.display_name,
      description: plan.description ?? '',
      is_global: plan.is_global,
      is_unit_based: plan.is_unit_based,
      price_per_unit: plan.price_per_unit != null ? String(plan.price_per_unit) : '',
      min_price: plan.min_price != null ? String(plan.min_price) : '',
      price_monthly: plan.price_monthly != null ? String(plan.price_monthly) : '',
      price_yearly: plan.price_yearly != null ? String(plan.price_yearly) : '',
      features_string: (plan.features ?? []).join(', '),
      terms_conditions: plan.terms_conditions ?? '',
    })
  }

  const validateForm = (): string | null => {
    if (!planForm.module || !planForm.display_name.trim()) {
      return 'Wybierz moduł i podaj nazwę planu.'
    }

    if (planForm.is_unit_based) {
      const pricePerUnit = parseFloat(planForm.price_per_unit)
      const minPrice = parseFloat(planForm.min_price)

      if (Number.isNaN(pricePerUnit) || pricePerUnit <= 0) {
        return 'Cena za lokal musi być większa niż 0.'
      }

      if (Number.isNaN(minPrice) || minPrice <= 0) {
        return 'Minimalna kwota musi być większa niż 0.'
      }
    } else {
      const monthly = parseFloat(planForm.price_monthly)
      const yearly = parseFloat(planForm.price_yearly)

      if ((Number.isNaN(monthly) || monthly <= 0) && (Number.isNaN(yearly) || yearly <= 0)) {
        return 'Wymagana cena miesięczna lub roczna.'
      }
    }

    return null
  }

  const savePlan = async () => {
    setFormError(null)

    const validationError = validateForm()
    if (validationError) {
      setFormError(validationError)
      return
    }

    setPlanSaving(true)

    try {
      const features = planForm.features_string
        .split(',')
        .map((f) => f.trim())
        .filter(Boolean)

      const input: CreatePricingPlanInput = {
        module: planForm.module as AppModule,
        display_name: planForm.display_name.trim(),
        description: planForm.description.trim() || undefined,
        is_global: planForm.is_global,
        is_unit_based: planForm.is_unit_based,
        features,
        terms_conditions: planForm.terms_conditions.trim() || undefined,
      }

      if (planForm.is_unit_based) {
        input.price_per_unit = parseFloat(planForm.price_per_unit)
        input.min_price = parseFloat(planForm.min_price)
      } else {
        const monthly = parseFloat(planForm.price_monthly)
        const yearly = parseFloat(planForm.price_yearly)
        if (!Number.isNaN(monthly) && monthly > 0) {
          input.price_monthly = monthly
        }
        if (!Number.isNaN(yearly) && yearly > 0) {
          input.price_yearly = yearly
        }
      }

      let result
      if (editingPlanId) {
        result = await updatePlan(editingPlanId, input)
      } else {
        result = await createPlan(input)
      }

      if (result.success) {
        toast.success(editingPlanId ? 'Plan zaktualizowany' : 'Plan utworzony')
        resetForm()
      } else {
        setFormError(result.error ?? 'Nie udało się zapisać planu.')
      }
    } catch (err) {
      console.error('[MonetizationPricingPlansSection] savePlan:', err)
      setFormError('Wystąpił błąd podczas zapisu planu.')
    } finally {
      setPlanSaving(false)
    }
  }

  const handleDelete = async (id: string) => {
    if (!window.confirm('Czy na pewno usunąć ten plan cenowy?')) return

    const result = await deletePlan(id)
    if (result.success) {
      toast.success('Plan usunięty')
      if (editingPlanId === id) resetForm()
    } else {
      toast.error(result.error ?? 'Nie udało się usunąć planu.')
    }
  }

  const togglePlanActive = async (plan: PricingPlan) => {
    const result = await updatePlan(plan.id, { is_active: !plan.is_active })
    if (result.success) {
      toast.success(plan.is_active ? 'Plan dezaktywowany' : 'Plan aktywowany')
    } else {
      toast.error(result.error ?? 'Nie udało się zmienić statusu.')
    }
  }

  const formatPrice = (price: number | null): string => {
    if (price == null) return '—'
    return `${price.toFixed(2)} zł`
  }

  const visiblePlans = plans.filter((plan) => MODULE_PLAN_MODULES.has(plan.module))

  return (
    <section aria-labelledby="monetization-pricing-heading">
      {error && (
        <div className="mb-4 bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {error}
        </div>
      )}

      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
        <h2
          id="monetization-pricing-heading"
          className="font-display text-xl font-semibold flex items-center gap-2"
        >
          <DollarSign className="h-6 w-6 text-primary" />
          Plany cenowe modułów
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
          <p className="text-sm font-medium text-foreground">
            {editingPlanId ? 'Edycja planu' : 'Nowy plan'}
          </p>

          {formError && (
            <div className="bg-destructive/10 border border-destructive/30 text-destructive px-3 py-2 rounded text-sm">
              {formError}
            </div>
          )}

          <div className="grid sm:grid-cols-2 gap-4">
            <label className="block space-y-1.5 text-sm">
              <span className="text-muted-foreground">Moduł</span>
              <select
                className={inputClass}
                value={planForm.module}
                onChange={(e) =>
                  setPlanForm((f) => ({ ...f, module: e.target.value as AppModule | '' }))
                }
              >
                <option value="">— Wybierz —</option>
                {MODULE_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </label>

            <label className="block space-y-1.5 text-sm">
              <span className="text-muted-foreground">Nazwa planu</span>
              <input
                className={inputClass}
                value={planForm.display_name}
                onChange={(e) => setPlanForm((f) => ({ ...f, display_name: e.target.value }))}
                placeholder="np. Standard, Premium"
              />
            </label>
          </div>

          <label className="block space-y-1.5 text-sm">
            <span className="text-muted-foreground">Opis</span>
            <textarea
              className={`${inputClass} min-h-[60px]`}
              value={planForm.description}
              onChange={(e) => setPlanForm((f) => ({ ...f, description: e.target.value }))}
              placeholder="Krótki opis planu"
            />
          </label>

          <div className="space-y-3 border-t border-border/60 pt-4">
            <p className="text-sm font-medium text-foreground">Typ planu</p>

            <label className="flex items-start gap-3 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={planForm.is_global}
                onChange={(e) => setPlanForm((f) => ({ ...f, is_global: e.target.checked }))}
                className="mt-1 h-4 w-4 rounded border-input text-primary focus:ring-ring"
              />
              <span className="text-sm text-foreground">
                Plan globalny (dla całej organizacji)
                <span className="block text-xs text-muted-foreground mt-1">
                  Jeśli odznaczone, plan dotyczy konkretnej wspólnoty.
                </span>
              </span>
            </label>

            <label className="flex items-start gap-3 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={planForm.is_unit_based}
                onChange={(e) => setPlanForm((f) => ({ ...f, is_unit_based: e.target.checked }))}
                className="mt-1 h-4 w-4 rounded border-input text-primary focus:ring-ring"
              />
              <span className="text-sm text-foreground">
                Cennik jednostkowy (wg liczby lokali)
                <span className="block text-xs text-muted-foreground mt-1">
                  Dla modułów typu home. Jeśli odznaczone, stosowany jest stały abonament.
                </span>
              </span>
            </label>
          </div>

          {planForm.is_unit_based ? (
            <div className="border-t border-border/60 pt-4 space-y-4">
              <p className="text-sm font-medium text-foreground">Cennik jednostkowy</p>
              <div className="grid sm:grid-cols-2 gap-4">
                <label className="block space-y-1.5 text-sm">
                  <span className="text-muted-foreground">Cena za lokal (zł)</span>
                  <input
                    type="number"
                    min={0}
                    step={0.01}
                    className={inputClass}
                    value={planForm.price_per_unit}
                    onChange={(e) => setPlanForm((f) => ({ ...f, price_per_unit: e.target.value }))}
                    placeholder="np. 5.00"
                  />
                </label>
                <label className="block space-y-1.5 text-sm">
                  <span className="text-muted-foreground">Minimalna kwota (zł)</span>
                  <input
                    type="number"
                    min={0}
                    step={0.01}
                    className={inputClass}
                    value={planForm.min_price}
                    onChange={(e) => setPlanForm((f) => ({ ...f, min_price: e.target.value }))}
                    placeholder="np. 100.00"
                  />
                </label>
              </div>
            </div>
          ) : (
            <div className="border-t border-border/60 pt-4 space-y-4">
              <p className="text-sm font-medium text-foreground">Cennik abonamentowy</p>
              <div className="grid sm:grid-cols-2 gap-4">
                <label className="block space-y-1.5 text-sm">
                  <span className="text-muted-foreground">Cena miesięczna (zł)</span>
                  <input
                    type="number"
                    min={0}
                    step={0.01}
                    className={inputClass}
                    value={planForm.price_monthly}
                    onChange={(e) => setPlanForm((f) => ({ ...f, price_monthly: e.target.value }))}
                    placeholder="np. 299.00"
                  />
                </label>
                <label className="block space-y-1.5 text-sm">
                  <span className="text-muted-foreground">Cena roczna (zł)</span>
                  <input
                    type="number"
                    min={0}
                    step={0.01}
                    className={inputClass}
                    value={planForm.price_yearly}
                    onChange={(e) => setPlanForm((f) => ({ ...f, price_yearly: e.target.value }))}
                    placeholder="np. 2990.00"
                  />
                </label>
              </div>
            </div>
          )}

          <label className="block space-y-1.5 text-sm">
            <span className="text-muted-foreground">Funkcje (features)</span>
            <textarea
              className={`${inputClass} min-h-[80px]`}
              value={planForm.features_string}
              onChange={(e) => setPlanForm((f) => ({ ...f, features_string: e.target.value }))}
              placeholder="Wpisz funkcje po przecinku, np. Dostęp dla mieszkańców, Powiadomienia push, API"
            />
          </label>

          <label className="block space-y-1.5 text-sm">
            <span className="text-muted-foreground">Regulamin (opcjonalnie)</span>
            <textarea
              className={`${inputClass} min-h-[80px]`}
              value={planForm.terms_conditions}
              onChange={(e) => setPlanForm((f) => ({ ...f, terms_conditions: e.target.value }))}
              placeholder="Warunki korzystania z tego planu"
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
              onClick={resetForm}
              className="inline-flex items-center gap-2 rounded-md border border-border px-4 py-2 text-sm hover:bg-muted"
            >
              <X className="h-4 w-4" />
              Anuluj
            </button>
          </div>
        </div>
      )}

      <div className="bento-card overflow-x-auto p-0">
        {loading && visiblePlans.length === 0 ? (
          <div className="p-8 text-center text-muted-foreground">Ładowanie...</div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border/60 text-left text-muted-foreground">
                <th className="p-4 font-medium">Moduł</th>
                <th className="p-4 font-medium">Nazwa planu</th>
                <th className="p-4 font-medium">Typ</th>
                <th className="p-4 font-medium">Ceny</th>
                <th className="p-4 font-medium">Status</th>
                <th className="p-4 font-medium text-right">Akcje</th>
              </tr>
            </thead>
            <tbody>
              {visiblePlans.map((plan) => (
                <tr key={plan.id} className="border-b border-border/40 last:border-0">
                  <td className="p-4 font-medium">{MODULE_DISPLAY_NAMES[plan.module]}</td>
                  <td className="p-4">
                    <div>
                      <div className="font-medium">{plan.display_name}</div>
                      {plan.description && (
                        <div className="text-xs text-muted-foreground mt-1">{plan.description}</div>
                      )}
                    </div>
                  </td>
                  <td className="p-4 text-muted-foreground">
                    <div className="text-xs space-y-1">
                      {plan.is_global && <div className="text-primary">• Globalny</div>}
                      {plan.is_unit_based ? (
                        <div>• Jednostkowy</div>
                      ) : (
                        <div>• Abonamentowy</div>
                      )}
                    </div>
                  </td>
                  <td className="p-4 text-muted-foreground">
                    {plan.is_unit_based ? (
                      <div className="text-xs space-y-1">
                        <div>{formatPrice(plan.price_per_unit)} / lokal</div>
                        <div className="text-muted-foreground">min. {formatPrice(plan.min_price)}</div>
                      </div>
                    ) : (
                      <div className="text-xs space-y-1">
                        {plan.price_monthly && <div>{formatPrice(plan.price_monthly)} / mies.</div>}
                        {plan.price_yearly && <div>{formatPrice(plan.price_yearly)} / rok</div>}
                      </div>
                    )}
                  </td>
                  <td className="p-4">
                    <span
                      className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                        plan.is_active
                          ? 'bg-primary/10 text-primary'
                          : 'bg-muted text-muted-foreground'
                      }`}
                    >
                      {plan.is_active ? 'Aktywny' : 'Nieaktywny'}
                    </span>
                  </td>
                  <td className="p-4 text-right whitespace-nowrap">
                    <button
                      type="button"
                      className="inline-flex items-center gap-1 text-primary hover:underline mr-3"
                      onClick={() => void togglePlanActive(plan)}
                      title={plan.is_active ? 'Dezaktywuj' : 'Aktywuj'}
                    >
                      <Check className="h-4 w-4" />
                    </button>
                    <button
                      type="button"
                      className="inline-flex items-center gap-1 text-primary hover:underline mr-3"
                      onClick={() => openEditPlan(plan)}
                    >
                      <Edit className="h-4 w-4" />
                    </button>
                    <button
                      type="button"
                      className="inline-flex items-center gap-1 text-destructive hover:underline"
                      onClick={() => void handleDelete(plan.id)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        {!loading && visiblePlans.length === 0 && (
          <div className="p-8 text-center text-muted-foreground">
            Brak planów. Dodaj pierwszy plan lub sprawdź uprawnienia.
          </div>
        )}
      </div>
    </section>
  )
}
