export const INBOUND_MAIL_DOMAIN =
  (import.meta.env.VITE_INBOUND_MAIL_DOMAIN as string | undefined)?.trim() || 'domio.com.pl'

const PL_MAP: Record<string, string> = {
  ą: 'a',
  ć: 'c',
  ę: 'e',
  ł: 'l',
  ń: 'n',
  ó: 'o',
  ś: 's',
  ź: 'z',
  ż: 'z',
}

/** Lowercase alphanumeric slug used in inbound aliases (`usterki+{module}-{slug}`). */
export function slugifyOrgName(name: string): string {
  const mapped = name
    .trim()
    .toLowerCase()
    .split('')
    .map((ch) => PL_MAP[ch] ?? ch)
    .join('')
  return mapped.replace(/[^a-z0-9]+/g, '').slice(0, 40)
}

export function isValidOrgSlug(slug: string): boolean {
  return /^[a-z0-9]{2,40}$/.test(slug)
}

export function inboundAliasPreview(slug: string, module = 'serwis'): string {
  const clean = slugifyOrgName(slug)
  return `usterki+${module}-${clean}@${INBOUND_MAIL_DOMAIN}`
}
