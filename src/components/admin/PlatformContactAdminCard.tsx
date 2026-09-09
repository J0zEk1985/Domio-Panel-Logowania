import { useCallback, useEffect, useState } from 'react'
import { Loader2, Save } from 'lucide-react'
import { toast } from 'sonner'
import { supabase } from '../../lib/supabase'
import { inputClass } from './pricingAdminUtils'
import {
  EMPTY_PLATFORM_CONTACT,
  PLATFORM_CONTACT_FIELDS,
  PLATFORM_CONTACT_KEYS,
  parsePlatformContact,
  validatePlatformContact,
  type PlatformContact,
} from '../../lib/platformContact'

const CONTACT_KEYS = Object.values(PLATFORM_CONTACT_KEYS)

export default function PlatformContactAdminCard() {
  const [form, setForm] = useState<PlatformContact>(EMPTY_PLATFORM_CONTACT)
  const [saved, setSaved] = useState<PlatformContact>(EMPTY_PLATFORM_CONTACT)
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [validationMessage, setValidationMessage] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoadError(null)
    setLoading(true)
    try {
      const { data, error } = await supabase
        .from('page_content')
        .select('content_key, content_value')
        .in('content_key', CONTACT_KEYS)

      if (error) {
        console.error('[PlatformContactAdminCard] load:', error)
        setLoadError('Nie udało się pobrać danych kontaktowych (sprawdź migrację i polityki RLS).')
        setForm(EMPTY_PLATFORM_CONTACT)
        setSaved(EMPTY_PLATFORM_CONTACT)
        return
      }

      const map = (data ?? []).reduce<Record<string, string>>((acc, row) => {
        acc[row.content_key] = row.content_value ?? ''
        return acc
      }, {})
      const parsed = parsePlatformContact(map)
      setForm(parsed)
      setSaved(parsed)
    } catch (e) {
      console.error('[PlatformContactAdminCard] load:', e)
      setLoadError('Wystąpił błąd podczas ładowania danych kontaktowych.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const hasChanges =
    form.name !== saved.name ||
    form.address !== saved.address ||
    form.registeredOffice !== saved.registeredOffice ||
    form.phone !== saved.phone ||
    form.email !== saved.email

  const setField = (field: keyof PlatformContact, value: string) => {
    setValidationMessage(null)
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  const save = async () => {
    const trimmed: PlatformContact = {
      name: form.name.trim(),
      address: form.address.trim(),
      registeredOffice: form.registeredOffice.trim(),
      phone: form.phone.trim(),
      email: form.email.trim(),
    }
    const check = validatePlatformContact(trimmed)
    if (!check.ok) {
      setValidationMessage(check.message)
      return
    }

    setSaving(true)
    try {
      for (const fieldDef of PLATFORM_CONTACT_FIELDS) {
        const content_value = trimmed[fieldDef.field]
        const { error } = await supabase
          .from('page_content')
          .update({ content_value, updated_at: new Date().toISOString() })
          .eq('content_key', fieldDef.key)

        if (error) {
          console.error('[PlatformContactAdminCard] save:', error)
          toast.error('Nie udało się zapisać danych kontaktowych.', {
            description: error.message || 'Spróbuj ponownie.',
          })
          return
        }
      }

      toast.success('Zapisano dane kontaktowe.')
      setForm(trimmed)
      setSaved(trimmed)
    } catch (e) {
      console.error('[PlatformContactAdminCard] save:', e)
      toast.error('Wystąpił nieoczekiwany błąd podczas zapisu.')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center gap-2 py-16 text-muted-foreground">
        <Loader2 className="h-5 w-5 animate-spin" />
        Ładowanie danych kontaktowych…
      </div>
    )
  }

  if (loadError) {
    return (
      <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl">
        {loadError}
      </div>
    )
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="font-display text-xl font-semibold">Dane kontaktowe</h2>
          <p className="text-sm text-muted-foreground mt-1">
            Wyświetlane na stronie logowania i w stopce. Przyciski telefonu i e-mailu otwierają aplikacje w telefonie.
          </p>
        </div>
        <button
          type="button"
          onClick={() => void save()}
          disabled={!hasChanges || saving}
          className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary text-primary-foreground px-4 py-2.5 text-sm font-medium shadow-sm hover:opacity-90 disabled:opacity-50 disabled:pointer-events-none transition-opacity shrink-0"
        >
          {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
          Zapisz
        </button>
      </div>

      {validationMessage ? (
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl">
          {validationMessage}
        </div>
      ) : null}

      <section className="bento-card border border-border/60 overflow-hidden">
        <header className="border-b border-border/50 px-5 py-4 bg-muted/30">
          <h3 className="font-display text-lg font-semibold">Dane identyfikacyjne</h3>
        </header>
        <div className="p-5 space-y-6">
          {PLATFORM_CONTACT_FIELDS.map((fieldDef) => {
            const id = `platform-contact-${fieldDef.field}`
            const value = form[fieldDef.field]
            return (
              <div key={fieldDef.key} className="space-y-2">
                <label htmlFor={id} className="block text-sm font-medium">
                  {fieldDef.label}
                </label>
                <p className="text-sm text-muted-foreground">{fieldDef.description}</p>
                {fieldDef.inputType === 'textarea' ? (
                  <textarea
                    id={id}
                    value={value}
                    onChange={(e) => setField(fieldDef.field, e.target.value)}
                    autoComplete={fieldDef.autoComplete}
                    placeholder={fieldDef.placeholder}
                    rows={3}
                    className={`${inputClass} min-h-[88px] resize-y font-sans`}
                  />
                ) : (
                  <input
                    id={id}
                    type={fieldDef.inputType}
                    value={value}
                    onChange={(e) => setField(fieldDef.field, e.target.value)}
                    autoComplete={fieldDef.autoComplete}
                    placeholder={fieldDef.placeholder}
                    inputMode={fieldDef.inputType === 'tel' ? 'tel' : undefined}
                    className={inputClass}
                  />
                )}
              </div>
            )
          })}
        </div>
      </section>
    </div>
  )
}
