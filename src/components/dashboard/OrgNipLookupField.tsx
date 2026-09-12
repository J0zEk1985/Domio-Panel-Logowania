import { useState } from 'react'
import {
  addressFromGus,
  lookupBillingNip,
  BillingNipLookupError,
  type BillingGusPreview,
} from '../../lib/billingNipLookup'
import type { LegalEntityKind } from '../../lib/legalEntityMessages'

const fieldClass =
  'w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-60'

type Props = {
  idPrefix: string
  nip: string
  disabled?: boolean
  onNipChange: (nip: string) => void
  onFilled: (filled: {
    name: string
    address: string
    city: string
    postalCode: string
    nip: string
    gusPreview: BillingGusPreview
    suggestedKind: LegalEntityKind
  }) => void
}

export function OrgNipLookupField({ idPrefix, nip, disabled, onNipChange, onFilled }: Props) {
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState<string | null>(null)

  const lookup = async () => {
    setBusy(true)
    setMessage(null)
    try {
      const result = await lookupBillingNip(nip)
      if (result.status === 'invalid_nip') {
        setMessage('Niepoprawny NIP. Sprawdź sumę kontrolną i 10 cyfr.')
        return
      }
      if (result.status === 'not_in_gus') {
        setMessage('Nie znaleziono podmiotu w GUS. Możesz uzupełnić dane ręcznie.')
        return
      }
      if (result.status === 'gus_inactive') {
        setMessage('Podmiot w GUS jest wykreślony.')
        return
      }
      if (result.status === 'gus_unavailable') {
        setMessage('Serwis GUS jest niedostępny. Uzupełnij dane ręcznie.')
        return
      }
      if (result.status === 'found_in_gus' && result.gusPreview) {
        const gus = result.gusPreview
        onFilled({
          name: gus.legalName,
          address: addressFromGus(gus),
          city: gus.city ?? '',
          postalCode: gus.postalCode ?? '',
          nip: gus.nip || nip.replace(/\D/g, ''),
          gusPreview: gus,
          suggestedKind: result.suggestedKind ?? 'company',
        })
        setMessage('Pobrano dane z GUS. Możesz je jeszcze poprawić przed zapisem.')
      }
    } catch (e) {
      console.error('[OrgNipLookupField] lookup:', e)
      setMessage(e instanceof BillingNipLookupError ? e.message : 'Nie udało się sprawdzić NIP.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="space-y-1.5">
      <label className="block text-sm text-muted-foreground" htmlFor={`${idPrefix}-nip`}>
        NIP
      </label>
      <div className="flex flex-col sm:flex-row gap-2">
        <input
          id={`${idPrefix}-nip`}
          className={fieldClass}
          value={nip}
          disabled={disabled || busy}
          inputMode="numeric"
          autoComplete="off"
          onChange={(e) => onNipChange(e.target.value)}
        />
        <button
          type="button"
          disabled={disabled || busy || nip.replace(/\D/g, '').length !== 10}
          onClick={() => void lookup()}
          className="inline-flex shrink-0 items-center justify-center rounded-md border border-border px-4 py-2 text-sm font-medium hover:bg-muted/60 disabled:opacity-50"
        >
          {busy ? 'Sprawdzanie…' : 'Sprawdź NIP'}
        </button>
      </div>
      {message ? <p className="text-xs text-muted-foreground">{message}</p> : null}
    </div>
  )
}
