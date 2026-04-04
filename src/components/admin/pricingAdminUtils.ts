import type { PricingPlanRow } from './pricingAdminTypes'

/** Parse DB jsonb features into string array. */
export function parseFeaturesFromDb(raw: unknown): string[] {
  if (Array.isArray(raw)) {
    return raw.map((x) => String(x).trim()).filter(Boolean)
  }
  if (raw && typeof raw === 'object' && 'length' in (raw as object)) {
    try {
      return Array.from(raw as unknown[]).map((x) => String(x).trim()).filter(Boolean)
    } catch {
      return []
    }
  }
  return []
}

export function formatMoneyPln(value: number | null | undefined): string {
  if (value == null || Number.isNaN(Number(value))) return '—'
  return `${Number(value).toLocaleString('pl-PL', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} zł`
}

export function formatDatePl(iso: string | null | undefined): string {
  if (!iso) return '—'
  try {
    return new Intl.DateTimeFormat('pl-PL', { dateStyle: 'medium' }).format(new Date(iso))
  } catch {
    return '—'
  }
}

export const inputClass =
  'w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring'

/** Empty or whitespace → null; otherwise non-negative integer or error. */
export function parseOptionalLimitInt(
  raw: string,
  label: string,
): { ok: true; value: number | null } | { ok: false; message: string } {
  const t = raw.trim()
  if (t === '') return { ok: true, value: null }
  const n = Number(t)
  if (!Number.isFinite(n) || !Number.isInteger(n) || n < 0) {
    return { ok: false, message: `${label} musi być pustym polem lub liczbą całkowitą ≥ 0.` }
  }
  return { ok: true, value: n }
}

/** Short summary for the plans table (Polish UI). */
export function formatPlanLimitsSummary(row: PricingPlanRow): string {
  const parts: string[] = []
  if (row.max_users != null) parts.push(`Użytkownicy: ${row.max_users}`)
  if (row.max_locations != null) parts.push(`Lokalizacje: ${row.max_locations}`)
  if (row.max_storage_gb != null) parts.push(`Pamięć: ${row.max_storage_gb} GB`)
  if (row.has_ai_features === true) parts.push('AI: Tak')
  if (parts.length === 0) return 'Bez limitu'
  return parts.join(', ')
}
