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
