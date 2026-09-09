export type PlatformContact = {
  name: string
  address: string
  registeredOffice: string
  phone: string
  email: string
}

export const PLATFORM_CONTACT_KEYS = {
  name: 'contact_name',
  address: 'contact_address',
  registeredOffice: 'contact_registered_office',
  phone: 'contact_phone',
  email: 'contact_email',
} as const

export type PlatformContactContentKey =
  (typeof PLATFORM_CONTACT_KEYS)[keyof typeof PLATFORM_CONTACT_KEYS]

export const EMPTY_PLATFORM_CONTACT: PlatformContact = {
  name: '',
  address: '',
  registeredOffice: '',
  phone: '',
  email: '',
}

export type PlatformContactFieldDef = {
  key: PlatformContactContentKey
  field: keyof PlatformContact
  label: string
  description: string
  inputType: 'text' | 'email' | 'tel' | 'textarea'
  autoComplete: string
  placeholder: string
  sortOrder: number
}

/** Structured fields aligned with schema.org Organization + Polish company imprint. */
export const PLATFORM_CONTACT_FIELDS: PlatformContactFieldDef[] = [
  {
    key: PLATFORM_CONTACT_KEYS.name,
    field: 'name',
    label: 'Nazwa',
    description: 'Nazwa firmy lub podmiotu (np. DOMIO Sp. z o.o.)',
    inputType: 'text',
    autoComplete: 'organization',
    placeholder: 'DOMIO Sp. z o.o.',
    sortOrder: 10,
  },
  {
    key: PLATFORM_CONTACT_KEYS.address,
    field: 'address',
    label: 'Adres',
    description: 'Adres korespondencyjny: ulica, numer, kod pocztowy, miejscowość',
    inputType: 'textarea',
    autoComplete: 'street-address',
    placeholder: 'ul. Przykładowa 1, 00-001 Warszawa',
    sortOrder: 20,
  },
  {
    key: PLATFORM_CONTACT_KEYS.registeredOffice,
    field: 'registeredOffice',
    label: 'Siedziba',
    description: 'Miejscowość lub adres siedziby rejestrowanej',
    inputType: 'text',
    autoComplete: 'address-level2',
    placeholder: 'Warszawa',
    sortOrder: 30,
  },
  {
    key: PLATFORM_CONTACT_KEYS.phone,
    field: 'phone',
    label: 'Telefon',
    description: 'Numer telefonu (zalecany format międzynarodowy, np. +48 123 456 789)',
    inputType: 'tel',
    autoComplete: 'tel',
    placeholder: '+48 123 456 789',
    sortOrder: 40,
  },
  {
    key: PLATFORM_CONTACT_KEYS.email,
    field: 'email',
    label: 'E-mail',
    description: 'Adres e-mail do kontaktu',
    inputType: 'email',
    autoComplete: 'email',
    placeholder: 'kontakt@przyklad.pl',
    sortOrder: 50,
  },
]

export const PLATFORM_CONTACT_KEY_SET = new Set<string>(
  PLATFORM_CONTACT_FIELDS.map((f) => f.key),
)

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

export function parsePlatformContact(map: Record<string, string | undefined | null>): PlatformContact {
  return {
    name: (map[PLATFORM_CONTACT_KEYS.name] ?? '').trim(),
    address: (map[PLATFORM_CONTACT_KEYS.address] ?? '').trim(),
    registeredOffice: (map[PLATFORM_CONTACT_KEYS.registeredOffice] ?? '').trim(),
    phone: (map[PLATFORM_CONTACT_KEYS.phone] ?? '').trim(),
    email: (map[PLATFORM_CONTACT_KEYS.email] ?? '').trim(),
  }
}

export function hasVisibleContact(contact: PlatformContact): boolean {
  return Boolean(
    contact.name ||
      contact.address ||
      contact.registeredOffice ||
      contact.phone ||
      contact.email,
  )
}

export function toTelHref(phone: string): string | null {
  const trimmed = phone.trim()
  if (!trimmed) return null
  const hasPlus = trimmed.startsWith('+')
  const digits = trimmed.replace(/\D/g, '')
  if (digits.length < 6) return null
  return `tel:${hasPlus ? '+' : ''}${digits}`
}

export function toMailtoHref(email: string): string | null {
  const trimmed = email.trim()
  if (!EMAIL_RE.test(trimmed)) return null
  return `mailto:${trimmed}`
}

export function validatePlatformContact(
  contact: PlatformContact,
): { ok: true } | { ok: false; message: string } {
  if (contact.email && !EMAIL_RE.test(contact.email)) {
    return { ok: false, message: 'Podaj poprawny adres e-mail albo zostaw pole puste.' }
  }
  if (contact.phone) {
    const digits = contact.phone.replace(/\D/g, '')
    if (digits.length < 6) {
      return { ok: false, message: 'Podaj poprawny numer telefonu albo zostaw pole puste.' }
    }
  }
  return { ok: true }
}

export function buildOrganizationJsonLd(contact: PlatformContact): Record<string, unknown> | null {
  if (!hasVisibleContact(contact)) return null

  const json: Record<string, unknown> = {
    '@context': 'https://schema.org',
    '@type': 'Organization',
  }

  if (contact.name) json.name = contact.name
  if (contact.phone) json.telephone = contact.phone
  if (contact.email) json.email = contact.email

  if (contact.address || contact.registeredOffice) {
    const postal: Record<string, string> = { '@type': 'PostalAddress' }
    if (contact.address) postal.streetAddress = contact.address
    if (contact.registeredOffice) postal.addressLocality = contact.registeredOffice
    postal.addressCountry = 'PL'
    json.address = postal
  }

  return json
}
