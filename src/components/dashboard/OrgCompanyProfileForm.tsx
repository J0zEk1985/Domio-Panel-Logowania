import { useCallback, useEffect, useState } from 'react'
import { toast } from 'sonner'
import { supabase } from '../../lib/supabase'
import { inboundAliasPreview, isValidOrgSlug, slugifyOrgName } from '../../lib/orgSlug'

const fieldClass =
  'w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-60'

type OrgProfile = {
  name: string
  slug: string
  nip: string | null
  address: string | null
  city: string | null
  postal_code: string | null
}

type Props = {
  organizationId: string
  canManage: boolean
  idPrefix?: string
  onSaved?: () => void
}

export function OrgCompanyProfileForm({ organizationId, canManage, idPrefix = 'org', onSaved }: Props) {
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [name, setName] = useState('')
  const [slug, setSlug] = useState('')
  const [savedSlug, setSavedSlug] = useState('')
  const [nip, setNip] = useState('')
  const [address, setAddress] = useState('')
  const [city, setCity] = useState('')
  const [postalCode, setPostalCode] = useState('')

  const load = useCallback(async () => {
    setLoadError(null)
    setLoading(true)
    try {
      const { data, error } = await supabase
        .from('organizations')
        .select('name, slug, nip, address, city, postal_code')
        .eq('id', organizationId)
        .maybeSingle()

      if (error) {
        console.error('[OrgCompanyProfileForm] load:', error)
        setLoadError('Nie udało się pobrać danych firmy.')
        return
      }
      const row = data as OrgProfile | null
      if (!row) {
        setLoadError('Nie znaleziono firmy.')
        return
      }
      setName(row.name ?? '')
      setSlug(row.slug ?? '')
      setSavedSlug(row.slug ?? '')
      setNip(row.nip ?? '')
      setAddress(row.address ?? '')
      setCity(row.city ?? '')
      setPostalCode(row.postal_code ?? '')
    } catch (e) {
      console.error('[OrgCompanyProfileForm] load:', e)
      setLoadError('Wystąpił błąd podczas ładowania danych firmy.')
    } finally {
      setLoading(false)
    }
  }, [organizationId])

  useEffect(() => {
    void load()
  }, [load])

  const save = async () => {
    setSaveError(null)
    const trimmedName = name.trim()
    const nextSlug = slugifyOrgName(slug || trimmedName)
    if (!trimmedName) {
      setSaveError('Nazwa firmy jest wymagana.')
      return
    }
    if (!isValidOrgSlug(nextSlug)) {
      setSaveError('Identyfikator firmy musi mieć 2–40 znaków: tylko małe litery i cyfry (bez spacji).')
      return
    }
    setSaving(true)
    try {
      const { error } = await supabase
        .from('organizations')
        .update({
          name: trimmedName,
          slug: nextSlug,
          nip: nip.trim() || null,
          address: address.trim() || null,
          city: city.trim() || null,
          postal_code: postalCode.trim() || null,
        })
        .eq('id', organizationId)

      if (error) {
        console.error('[OrgCompanyProfileForm] save:', error)
        if (error.code === '23505') {
          setSaveError('Ten identyfikator firmy jest już zajęty. Wybierz inny.')
          return
        }
        setSaveError(error.message || 'Nie udało się zapisać zmian.')
        return
      }

      setSlug(nextSlug)
      if (nextSlug !== savedSlug) {
        const { error: syncErr } = await supabase.rpc('sync_org_inbound_mailbox_aliases', {
          p_org_id: organizationId,
        })
        if (syncErr) {
          console.error('[OrgCompanyProfileForm] sync aliases:', syncErr)
          toast.success('Zapisano dane firmy. Aliasy e-mail nie zostały zaktualizowane — odśwież skrzynki później.')
        } else {
          toast.success('Zapisano dane firmy i zaktualizowano aliasy e-mail.')
        }
      } else {
        toast.success('Zapisano dane firmy.')
      }
      setSavedSlug(nextSlug)
      onSaved?.()
    } catch (e) {
      console.error('[OrgCompanyProfileForm] save:', e)
      setSaveError('Wystąpił nieoczekiwany błąd podczas zapisu.')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return <p className="text-sm text-muted-foreground">Ładowanie danych firmy…</p>
  }
  if (loadError) {
    return (
      <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
        {loadError}
      </div>
    )
  }

  const previewSlug = slugifyOrgName(slug || name)
  const aliasPreview = previewSlug.length >= 2 ? inboundAliasPreview(previewSlug) : null

  return (
    <div className="space-y-4">
      {saveError && (
        <div className="bg-destructive/10 border border-destructive/30 text-destructive px-4 py-3 rounded-xl text-sm">
          {saveError}
        </div>
      )}
      <div className="grid sm:grid-cols-2 gap-4">
        <div className="space-y-1.5 sm:col-span-2">
          <label className="block text-sm text-muted-foreground" htmlFor={`${idPrefix}-name`}>
            Nazwa firmy
          </label>
          <input
            id={`${idPrefix}-name`}
            className={fieldClass}
            value={name}
            disabled={!canManage || saving}
            onChange={(e) => setName(e.target.value)}
          />
        </div>
        <div className="space-y-1.5 sm:col-span-2">
          <label className="block text-sm text-muted-foreground" htmlFor={`${idPrefix}-slug`}>
            Identyfikator w aliasie e-mail
          </label>
          <input
            id={`${idPrefix}-slug`}
            className={fieldClass}
            value={slug}
            disabled={!canManage || saving}
            autoCapitalize="none"
            autoCorrect="off"
            spellCheck={false}
            onChange={(e) => setSlug(slugifyOrgName(e.target.value))}
          />
          <p className="text-xs text-muted-foreground">
            Tylko małe litery i cyfry. Ten identyfikator wchodzi w skład aliasu Domio
            {aliasPreview ? (
              <>
                , np. <code className="bg-muted px-1 py-0.5 rounded">{aliasPreview}</code>
              </>
            ) : null}
            . Zmiana zaktualizuje istniejące aliasy.
          </p>
          {canManage && name.trim() && slugifyOrgName(name) !== slug ? (
            <button
              type="button"
              className="text-xs font-medium text-primary hover:underline"
              onClick={() => setSlug(slugifyOrgName(name))}
            >
              Użyj nazwy firmy jako identyfikatora
            </button>
          ) : null}
        </div>
        <div className="space-y-1.5">
          <label className="block text-sm text-muted-foreground" htmlFor={`${idPrefix}-nip`}>
            NIP
          </label>
          <input
            id={`${idPrefix}-nip`}
            className={fieldClass}
            value={nip}
            disabled={!canManage || saving}
            onChange={(e) => setNip(e.target.value)}
          />
        </div>
        <div className="space-y-1.5">
          <label className="block text-sm text-muted-foreground" htmlFor={`${idPrefix}-city`}>
            Miasto
          </label>
          <input
            id={`${idPrefix}-city`}
            className={fieldClass}
            value={city}
            disabled={!canManage || saving}
            onChange={(e) => setCity(e.target.value)}
          />
        </div>
        <div className="space-y-1.5 sm:col-span-2">
          <label className="block text-sm text-muted-foreground" htmlFor={`${idPrefix}-address`}>
            Adres
          </label>
          <input
            id={`${idPrefix}-address`}
            className={fieldClass}
            value={address}
            disabled={!canManage || saving}
            onChange={(e) => setAddress(e.target.value)}
          />
        </div>
        <div className="space-y-1.5">
          <label className="block text-sm text-muted-foreground" htmlFor={`${idPrefix}-postal`}>
            Kod pocztowy
          </label>
          <input
            id={`${idPrefix}-postal`}
            className={fieldClass}
            value={postalCode}
            disabled={!canManage || saving}
            onChange={(e) => setPostalCode(e.target.value)}
          />
        </div>
      </div>
      {canManage ? (
        <button
          type="button"
          disabled={saving}
          onClick={() => void save()}
          className="inline-flex items-center justify-center rounded-md bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground hover:opacity-90 disabled:opacity-50"
        >
          {saving ? 'Zapisywanie…' : 'Zapisz dane firmy'}
        </button>
      ) : (
        <p className="text-xs text-muted-foreground">Podgląd. Zmiany zapisze właściciel lub administrator firmy.</p>
      )}
    </div>
  )
}
