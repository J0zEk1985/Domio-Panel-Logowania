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
