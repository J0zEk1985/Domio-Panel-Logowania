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

/** Company / membership roles shown in the admin role menu. */
export const MEMBERSHIP_ROLE_OPTIONS: { value: string; label: string }[] = [
  { value: 'owner', label: 'Właściciel' },
  { value: 'admin', label: 'Administrator firmy' },
  { value: 'coordinator', label: 'Koordynator' },
  { value: 'manager', label: 'Menedżer' },
  { value: 'technik', label: 'Technik' },
  { value: 'cleaner', label: 'Pracownik (sprzątanie)' },
]

export function membershipRoleLabel(role: string): string {
  const r = role.trim().toLowerCase()
  if (r === 'owner' || r === 'wlasciciel') return 'Właściciel'
  if (r === 'admin' || r === 'administrator') return 'Administrator firmy'
  if (r === 'coordinator' || r === 'koordynator') return 'Koordynator'
  if (r === 'manager') return 'Menedżer'
  if (r === 'technik') return 'Technik'
  if (r === 'cleaner' || r === 'staff') return 'Pracownik (sprzątanie)'
  return role.trim() || '—'
}

/** Platform-wide role (profiles.platform_role), not the company membership role. */
export function platformRoleLabel(role: string | null | undefined): string {
  const r = (role ?? '').trim().toLowerCase()
  if (r === 'admin') return 'Administrator platformy'
  if (r === 'user' || r === '') return 'Użytkownik'
  return role!.trim()
}

export function isSimplifiedAccount(accountType: string | null | undefined): boolean {
  return (accountType ?? '').trim().toLowerCase() === 'simplified'
}

export function accountTypeLabel(accountType: string | null | undefined): string {
  return isSimplifiedAccount(accountType) ? 'Uproszczone' : 'Pełne'
}

export function taskLogActionLabel(actionType: string | null | undefined): string {
  const a = (actionType ?? '').trim().toUpperCase()
  if (a === 'CHECK_IN') return 'Zameldowanie na obiekcie'
  if (a === 'CHECK_OUT') return 'Wymeldowanie z obiektu'
  return actionType?.trim() || '—'
}
