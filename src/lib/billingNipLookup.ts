import { supabase } from './supabase'
import { legalEntityErrorMessage, type LegalEntityKind } from './legalEntityMessages'

export type BillingGusPreview = {
  nip: string
  regon: string | null
  krs: string | null
  legalName: string
  city: string | null
  postalCode: string | null
  street: string | null
  buildingNumber: string | null
  apartmentNumber: string | null
  seatFullAddress: string
  voivodeship: string | null
  county: string | null
  commune: string | null
  legalFormCode: string | null
  legalFormName: string | null
  endedAt: string | null
}

export type BillingNipLookupResult = {
  status:
    | 'invalid_nip'
    | 'found_in_gus'
    | 'not_in_gus'
    | 'gus_inactive'
    | 'gus_unavailable'
  gusPreview: BillingGusPreview | null
  suggestedKind?: LegalEntityKind
}

export class BillingNipLookupError extends Error {
  readonly code: string
  constructor(code: string) {
    super(billingNipErrorMessage(code))
    this.name = 'BillingNipLookupError'
    this.code = code
  }
}

export function billingNipErrorMessage(code: string): string {
  switch (code) {
    case 'invalid_nip':
      return 'Niepoprawny NIP. Sprawdź sumę kontrolną i 10 cyfr.'
    case 'not_in_gus':
      return 'Nie znaleziono podmiotu w GUS. Możesz uzupełnić dane ręcznie.'
    case 'gus_inactive':
      return 'Podmiot w GUS jest wykreślony. Nie można go dodać do katalogu.'
    case 'gus_unavailable':
    case 'GUS_NOT_CONFIGURED':
    case 'GUS_LOGIN_FAILED':
    case 'GUS_FAILED':
      return 'Serwis GUS jest niedostępny. Uzupełnij dane ręcznie.'
    case 'PROVIDER_DIRECTORY_NIP_REQUIRED':
      return 'Aby być widocznym w katalogu, najpierw zapisz NIP zweryfikowany w GUS.'
    case 'PROVIDER_DIRECTORY_GUS_REQUIRED':
      return 'Aby być widocznym w katalogu, kliknij „Sprawdź NIP” i zapisz dane z GUS.'
    case 'PROVIDER_DIRECTORY_CONTACT_REQUIRED':
      return 'Aby być widocznym w katalogu, podaj telefon (min. 9 cyfr) oraz miasto i kod pocztowy.'
    default:
      if (code.startsWith('GUS_HTTP_')) {
        return 'Serwis GUS jest niedostępny. Uzupełnij dane ręcznie.'
      }
      return legalEntityErrorMessage(code)
  }
}

export function addressFromGus(gus: BillingGusPreview): string {
  const line = [gus.street, gus.buildingNumber, gus.apartmentNumber]
    .map((part) => part?.trim())
    .filter((part): part is string => Boolean(part))
    .join(' ')
  return line || gus.seatFullAddress || ''
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, unknown>
  }
  return null
}

export async function lookupBillingNip(nip: string): Promise<BillingNipLookupResult> {
  const { data, error } = await supabase.functions.invoke('lookup-legal-entity', {
    body: { action: 'billingLookup', nip },
  })

  let payload = asRecord(data)
  if (error) {
    const context = (error as { context?: Response }).context
    if (context && typeof context.json === 'function') {
      try {
        payload = asRecord(await context.json()) ?? payload
      } catch {
        console.error('[billingNipLookup] parse error body failed')
      }
    }
    const code =
      (typeof payload?.error === 'string' && payload.error) ||
      (typeof payload?.status === 'string' && payload.status) ||
      'RPC_FAILED'
    console.error('[billingNipLookup]', code, error)
    throw new BillingNipLookupError(code)
  }

  if (payload && typeof payload.error === 'string') {
    throw new BillingNipLookupError(payload.error)
  }
  if (!payload) {
    throw new BillingNipLookupError('RPC_FAILED')
  }
  return payload as unknown as BillingNipLookupResult
}
