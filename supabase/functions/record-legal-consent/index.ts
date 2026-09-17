import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import { buildLegalAcceptancePdf, sha256Hex, type LegalPdfDocument } from './pdf.ts'

/**
 * Gateway verify_jwt stays false. Caller JWT is required inside.
 * Writes go through service_role RPCs after getUser(jwt).
 */

const ALLOWED_ORIGINS = [
  'https://udomio.com.pl',
  'https://www.udomio.com.pl',
  'https://test.udomio.com.pl',
  'https://home.domio.com.pl',
  'https://test.home.domio.com.pl',
  'https://admin.domio.com.pl',
  'https://test.admin.domio.com.pl',
  'https://adm.domio.com.pl',
  'https://test.adm.domio.com.pl',
  'https://serwis.domio.com.pl',
  'https://test.serwis.domio.com.pl',
  'https://cleaning.domio.com.pl',
  'https://test.cleaning.domio.com.pl',
  'https://domio.com.pl',
  'https://www.domio.com.pl',
  'https://test.domio.com.pl',
  'http://localhost:3000',
  'http://localhost:5173',
  'http://localhost:8080',
  'http://127.0.0.1:3000',
  'http://127.0.0.1:5173',
  'http://127.0.0.1:8080',
]

const SOURCES = new Set(['signup_email', 'signup_oauth', 'reacceptance'])

function getCorsHeaders(req: Request) {
  const origin = req.headers.get('Origin') ?? ''
  const allowOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0]
  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    Vary: 'Origin',
  }
}

function json(cors: Record<string, string>, status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })
}

function mapLegalError(message: string): { status: number; error: string } {
  if (message.includes('LEGAL_DOCUMENTS_STALE')) {
    return { status: 409, error: 'Dokumenty prawne zostały zaktualizowane. Odśwież stronę i zaakceptuj aktualną wersję.' }
  }
  if (message.includes('LEGAL_REQUIRED_DOCS_MISSING')) {
    return { status: 400, error: 'Musisz zaakceptować wszystkie wymagane dokumenty prawne.' }
  }
  if (message.includes('LEGAL_DOCUMENTS_REQUIRED')) {
    return { status: 400, error: 'Brak listy zaakceptowanych dokumentów.' }
  }
  if (message.includes('LEGAL_SOURCE_INVALID')) {
    return { status: 400, error: 'Nieprawidłowe źródło akceptacji.' }
  }
  if (message.includes('LEGAL_EMAIL_REQUIRED')) {
    return { status: 400, error: 'Brak adresu e-mail na koncie.' }
  }
  return { status: 500, error: 'Nie udało się zapisać akceptacji dokumentów.' }
}

function asUuidArray(value: unknown): string[] {
  if (!Array.isArray(value)) return []
  return [...new Set(value.map((item) => String(item ?? '').trim()).filter(Boolean))]
}

Deno.serve(async (req) => {
  const cors = getCorsHeaders(req)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors })
  }
  if (req.method !== 'POST') {
    return json(cors, 405, { error: 'Method not allowed' })
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !serviceRoleKey) {
    return json(cors, 500, { error: 'Missing server configuration' })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.toLowerCase().startsWith('bearer ')) {
    return json(cors, 401, { error: 'Unauthorized' })
  }
  const callerJwt = authHeader.slice(7).trim()

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  const { data: callerData, error: callerError } = await admin.auth.getUser(callerJwt)
  const userId = callerData.user?.id
  const userEmail = callerData.user?.email ?? null
  if (callerError || !userId) {
    return json(cors, 401, { error: 'Unauthorized' })
  }

  let body: Record<string, unknown>
  try {
    body = (await req.json()) as Record<string, unknown>
  } catch {
    return json(cors, 400, { error: 'Nieprawidłowe ciało żądania.' })
  }

  const source = String(body.source ?? '').trim()
  if (!SOURCES.has(source)) {
    return json(cors, 400, { error: 'Nieprawidłowe źródło akceptacji.' })
  }

  const acceptedDocumentIds = asUuidArray(body.acceptedDocumentIds ?? body.accepted_document_ids)
  if (acceptedDocumentIds.length === 0) {
    return json(cors, 400, { error: 'Brak listy zaakceptowanych dokumentów.' })
  }

  const ipAddress = typeof body.ipAddress === 'string'
    ? body.ipAddress
    : typeof body.ip_address === 'string'
      ? body.ip_address
      : null
  const userAgent = req.headers.get('user-agent')

  const { data: beginRaw, error: beginError } = await admin.rpc('begin_legal_consent', {
    p_user_id: userId,
    p_source: source,
    p_email: userEmail,
    p_ip_address: ipAddress,
    p_user_agent: userAgent,
    p_document_ids: acceptedDocumentIds,
  })

  if (beginError) {
    console.error('[record-legal-consent] begin:', beginError)
    const mapped = mapLegalError(beginError.message || '')
    return json(cors, mapped.status, { error: mapped.error })
  }

  const begin = (beginRaw ?? {}) as Record<string, unknown>
  if (begin.already_recorded === true) {
    const dispatchId = begin.dispatch_id ? String(begin.dispatch_id) : null
    if (dispatchId) {
      await notifyN8n(dispatchId)
    }
    return json(cors, 200, {
      ok: true,
      alreadyRecorded: true,
      batchId: begin.batch_id ?? null,
      dispatchId,
    })
  }

  const batchId = String(begin.batch_id ?? '')
  const documents = (Array.isArray(begin.documents) ? begin.documents : []) as LegalPdfDocument[]
    const documentIds = (
      Array.isArray(begin.document_ids)
        ? (begin.document_ids as unknown[])
        : documents.map((doc) => doc.id)
    )
      .map((id) => String(id ?? '').trim())
      .filter(Boolean)

  if (!batchId || documents.length === 0) {
    return json(cors, 500, { error: 'Nie udało się przygotować dokumentów do PDF.' })
  }

  try {
    const pdfBytes = await buildLegalAcceptancePdf({
      email: String(begin.email ?? userEmail ?? ''),
      acceptedAt: String(begin.accepted_at ?? new Date().toISOString()),
      ipAddress: (begin.ip_address as string | null) ?? ipAddress,
      userAgent: (begin.user_agent as string | null) ?? userAgent,
      documents,
    })
    const pdfSha256 = await sha256Hex(pdfBytes)
    const storagePath = `${userId}/${batchId}.pdf`

    const upload = await admin.storage.from('legal-acceptances').upload(storagePath, pdfBytes, {
      contentType: 'application/pdf',
      upsert: true,
    })
    if (upload.error) {
      console.error('[record-legal-consent] storage:', upload.error)
      return json(cors, 500, { error: 'Nie udało się zapisać pliku PDF.' })
    }

    const { data: finalizeRaw, error: finalizeError } = await admin.rpc('finalize_legal_consent', {
      p_batch_id: batchId,
      p_pdf_sha256: pdfSha256,
      p_pdf_storage_path: storagePath,
      p_document_ids: documentIds.filter(Boolean),
    })

    if (finalizeError) {
      console.error('[record-legal-consent] finalize:', finalizeError)
      const mapped = mapLegalError(finalizeError.message || '')
      return json(cors, mapped.status, { error: mapped.error })
    }

    const finalize = (finalizeRaw ?? {}) as Record<string, unknown>
    const dispatchId = finalize.dispatch_id ? String(finalize.dispatch_id) : null
    let emailQueued = false
    if (dispatchId) {
      emailQueued = await notifyN8n(dispatchId)
    }

    return json(cors, 200, {
      ok: true,
      alreadyRecorded: false,
      batchId,
      dispatchId,
      emailQueued,
    })
  } catch (err) {
    console.error('[record-legal-consent] pdf:', err)
    return json(cors, 500, { error: 'Nie udało się wygenerować pliku PDF.' })
  }
})

async function notifyN8n(dispatchId: string): Promise<boolean> {
  const webhookUrl = Deno.env.get('LEGAL_WELCOME_N8N_WEBHOOK_URL')
  if (!webhookUrl) {
    console.warn('[record-legal-consent] LEGAL_WELCOME_N8N_WEBHOOK_URL is not set; email stays pending')
    return false
  }
  try {
    const res = await fetch(webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ dispatchId }),
    })
    if (!res.ok) {
      console.error('[record-legal-consent] n8n status:', res.status, await res.text())
      return false
    }
    return true
  } catch (err) {
    console.error('[record-legal-consent] n8n:', err)
    return false
  }
}
