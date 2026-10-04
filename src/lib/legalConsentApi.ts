import { supabase } from './supabase'
import type { LegalConsentSource, PendingRequiredLegalDocument } from '../types/database'

export const SIGNUP_ACCEPTED_DOCUMENT_IDS_KEY = 'accepted_legal_document_ids'

type RecordLegalConsentResult = {
  ok: boolean
  alreadyRecorded?: boolean
  batchId?: string | null
  dispatchId?: string | null
  emailQueued?: boolean
  skipped?: boolean
  error?: string
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, unknown>
  }
  return null
}

export async function fetchClientIp(): Promise<string | null> {
  try {
    const response = await fetch('https://api.ipify.org?format=json')
    const data = (await response.json()) as { ip?: string }
    return data.ip || null
  } catch (err) {
    console.error('[legalConsentApi] ip:', err)
    return null
  }
}

export async function fetchPendingRequiredLegalDocuments(): Promise<PendingRequiredLegalDocument[]> {
  const { data, error } = await supabase.rpc('pending_required_legal_documents')
  if (error) {
    console.error('[legalConsentApi] pending_required_legal_documents:', error)
    throw new Error('Nie udało się sprawdzić akceptacji dokumentów prawnych.')
  }
  const rows = Array.isArray(data) ? data : []
  return rows.map((row) => {
    const rec = asRecord(row) ?? {}
    return {
      id: String(rec.id ?? ''),
      document_type: rec.document_type as PendingRequiredLegalDocument['document_type'],
      version: String(rec.version ?? ''),
      active_from: String(rec.active_from ?? ''),
    }
  }).filter((row) => row.id)
}

export async function recordPlatformLegalConsent(input: {
  acceptedDocumentIds: string[]
  source: LegalConsentSource
  ipAddress: string | null
}): Promise<RecordLegalConsentResult> {
  const { data: sessionData, error: sessionError } = await supabase.auth.getSession()
  if (sessionError) {
    console.error('[legalConsentApi] getSession:', sessionError)
  }
  const accessToken = sessionData.session?.access_token
  if (!accessToken) {
    return { ok: false, error: 'Brak sesji. Zaloguj się ponownie.' }
  }

  const { data, error } = await supabase.functions.invoke('record-legal-consent', {
    body: {
      acceptedDocumentIds: input.acceptedDocumentIds,
      source: input.source,
      ipAddress: input.ipAddress,
    },
    headers: { Authorization: `Bearer ${accessToken}` },
  })

  const payload = asRecord(data)
  if (error) {
    console.error('[legalConsentApi] invoke:', error, payload)
    const message =
      (typeof payload?.error === 'string' && payload.error) ||
      'Nie udało się zapisać akceptacji i wysłać dokumentów PDF.'
    return { ok: false, error: message }
  }
  if (payload && payload.ok === false) {
    return {
      ok: false,
      error: typeof payload.error === 'string' ? payload.error : 'Nie udało się zapisać akceptacji.',
    }
  }

  return {
    ok: true,
    alreadyRecorded: payload?.alreadyRecorded === true,
    batchId: payload?.batchId ? String(payload.batchId) : null,
    dispatchId: payload?.dispatchId ? String(payload.dispatchId) : null,
    emailQueued: payload?.emailQueued === true,
  }
}

export function readSignupAcceptedDocumentIds(metadata: unknown): string[] {
  const record = asRecord(metadata)
  const raw = record?.[SIGNUP_ACCEPTED_DOCUMENT_IDS_KEY]
  if (!Array.isArray(raw)) return []
  return [...new Set(raw.map((item) => String(item ?? '').trim()).filter((id) => id.length > 0))]
}

/** Records checkbox choices stored at email signup, once a session exists. */
export async function recordSignupLegalConsentFromMetadata(): Promise<RecordLegalConsentResult> {
  const { data, error } = await supabase.auth.getUser()
  if (error || !data.user) {
    console.error('[legalConsentApi] getUser:', error)
    return { ok: false, error: 'Brak sesji. Zaloguj się ponownie.' }
  }

  const acceptedDocumentIds = readSignupAcceptedDocumentIds(data.user.user_metadata)
  if (acceptedDocumentIds.length === 0) {
    return { ok: true, skipped: true }
  }

  const ipAddress = await fetchClientIp()
  const result = await recordPlatformLegalConsent({
    acceptedDocumentIds,
    source: 'signup_email',
    ipAddress,
  })
  if (!result.ok) return result

  const { error: clearError } = await supabase.auth.updateUser({
    data: { [SIGNUP_ACCEPTED_DOCUMENT_IDS_KEY]: null },
  })
  if (clearError) {
    console.error('[legalConsentApi] clear signup metadata:', clearError)
  }
  return result
}
