export type LegalDocType = 'terms' | 'privacy' | 'marketing'

export type LegalDocumentRow = {
  id: string
  document_type: LegalDocType
  version: string
  content: string
  is_active: boolean
  is_required: boolean
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
  marketing: 'Zgody marketingowe',
}
