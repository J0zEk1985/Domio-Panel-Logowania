import { supabase } from './supabase'
import type { LegalConsentSource, PendingRequiredLegalDocument } from '../types/database'

type RecordLegalConsentResult = {
  ok: boolean
  alreadyRecorded?: boolean
  batchId?: string | null
  dispatchId?: string | null
  emailQueued?: boolean
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
