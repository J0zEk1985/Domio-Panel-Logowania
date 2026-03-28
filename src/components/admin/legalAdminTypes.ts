export type LegalDocType = 'terms' | 'privacy'

export type LegalDocumentRow = {
  id: string
  document_type: LegalDocType
  version: string
  content: string
  is_active: boolean
  published_at: string
  created_by: string | null
}

export function formatPublishedLegal(iso: string): string {
  try {
    return new Intl.DateTimeFormat('pl-PL', {
      dateStyle: 'medium',
      timeStyle: 'short',
    }).format(new Date(iso))
  } catch {
    return '—'
  }
}

export const DOC_LABELS: Record<LegalDocType, string> = {
  terms: 'Regulamin',
  privacy: 'Polityka prywatności',
}
