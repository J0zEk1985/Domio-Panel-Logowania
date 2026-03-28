export function formatDateTime(iso: string | null | undefined): string {
  if (!iso) return '—'
  try {
    return new Intl.DateTimeFormat('pl-PL', {
      dateStyle: 'short',
      timeStyle: 'short',
    }).format(new Date(iso))
  } catch {
    return '—'
  }
}

export function formatDateOnly(iso: string | null | undefined): string {
  if (!iso) return '—'
  try {
    return new Intl.DateTimeFormat('pl-PL', { dateStyle: 'medium' }).format(new Date(iso))
  } catch {
    return '—'
  }
}

/** Display name: first + last, else full_name, else em dash */
export function displayPersonName(p: {
  first_name?: string | null
  last_name?: string | null
  full_name?: string | null
}): string {
  const fn = p.first_name?.trim()
  const ln = p.last_name?.trim()
  if (fn || ln) {
    return [fn, ln].filter(Boolean).join(' ')
  }
  const full = p.full_name?.trim()
  return full || '—'
}

export function nestedName(
  rel: { name: string } | { name: string }[] | null | undefined,
): string {
  if (!rel) return '—'
  if (Array.isArray(rel)) return rel[0]?.name?.trim() ?? '—'
  return rel.name?.trim() ?? '—'
}

export function membershipRoleLabel(role: string): string {
  const r = role.trim().toLowerCase()
  if (r === 'owner') return 'Właściciel'
  if (r === 'coordinator') return 'Koordynator'
  if (r === 'cleaner') return 'Sprzątacz'
  return role
}
