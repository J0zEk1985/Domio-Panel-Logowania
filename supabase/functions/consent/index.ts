import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const ALLOWED_ORIGINS = [
  'https://cleaning.domio.com.pl',
  'https://test.cleaning.domio.com.pl',
  'https://serwis.domio.com.pl',
  'https://test.serwis.domio.com.pl',
  'https://admin.domio.com.pl',
  'https://test.admin.domio.com.pl',
  'https://adm.domio.com.pl',
  'https://test.adm.domio.com.pl',
  'https://home.domio.com.pl',
  'https://test.home.domio.com.pl',
  'https://flota.domio.com.pl',
  'https://test.flota.domio.com.pl',
  'https://domio.com.pl',
  'https://www.domio.com.pl',
  'https://test.domio.com.pl',
  'https://udomio.com.pl',
  'https://www.udomio.com.pl',
  'https://test.udomio.com.pl',
]

const ACTIONS = new Set(['accept_all', 'reject_optional', 'customize', 'withdraw'])
const APP_SOURCES = new Set(['hub', 'cleaning', 'serwis', 'administracja', 'home', 'flota'])
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

function isAllowedOrigin(origin: string): boolean {
  if (ALLOWED_ORIGINS.includes(origin)) return true
  try {
    const url = new URL(origin)
    return url.hostname === 'localhost' || url.hostname === '127.0.0.1'
  } catch {
    return false
  }
}

function getCorsHeaders(req: Request) {
  const origin = req.headers.get('Origin') ?? ''
  const allowOrigin = isAllowedOrigin(origin) ? origin : ALLOWED_ORIGINS[0]
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

function clientIp(req: Request): string {
  const forwarded = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim()
  const cf = req.headers.get('cf-connecting-ip')?.trim()
  const real = req.headers.get('x-real-ip')?.trim()
  return forwarded || cf || real || '0.0.0.0'
}

async function sha256Hex(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value)
  const digest = await crypto.subtle.digest('SHA-256', bytes)
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

function asBoolean(value: unknown): boolean {
  return value === true
}

function parseBody(raw: unknown): {
  consentId: string
  policyVersion: string
  action: string
  appSource: string
  categories: { essential: true; functional: boolean; analytics: boolean; marketing: boolean }
} | null {
  if (!raw || typeof raw !== 'object') return null
  const body = raw as Record<string, unknown>
  const consentId = String(body.consent_id ?? body.consentId ?? '').trim()
  const policyVersion = String(body.policy_version ?? body.policyVersion ?? '').trim()
  const action = String(body.action ?? '').trim()
  const appSource = String(body.app_source ?? body.appSource ?? '').trim()
  const categoriesRaw =
    body.accepted_categories && typeof body.accepted_categories === 'object'
      ? (body.accepted_categories as Record<string, unknown>)
      : body.categories && typeof body.categories === 'object'
        ? (body.categories as Record<string, unknown>)
        : null

  if (!UUID_RE.test(consentId)) return null
  if (!policyVersion || policyVersion.length > 32) return null
  if (!ACTIONS.has(action) || !APP_SOURCES.has(appSource) || !categoriesRaw) return null

  return {
    consentId,
    policyVersion,
    action,
    appSource,
    categories: {
      essential: true,
      functional: asBoolean(categoriesRaw.functional),
      analytics: asBoolean(categoriesRaw.analytics),
      marketing: asBoolean(categoriesRaw.marketing),
    },
  }
}

Deno.serve(async (req) => {
  const cors = getCorsHeaders(req)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors })
  }
  if (req.method !== 'POST') {
    return json(cors, 405, { error: 'METHOD_NOT_ALLOWED' })
  }

  let parsed: unknown
  try {
    parsed = await req.json()
  } catch (error) {
    console.error('[consent] invalid JSON', error)
    return json(cors, 400, { error: 'INVALID_JSON' })
  }

  const payload = parseBody(parsed)
  if (!payload) {
    return json(cors, 400, { error: 'INVALID_PAYLOAD' })
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  if (!supabaseUrl || !serviceKey) {
    console.error('[consent] missing service configuration')
    return json(cors, 500, { error: 'SERVER_MISCONFIGURED' })
  }

  let userId: string | null = null
  const authorization = req.headers.get('Authorization') ?? ''
  if (authorization.startsWith('Bearer ') && anonKey) {
    try {
      const userClient = createClient(supabaseUrl, anonKey, {
        global: { headers: { Authorization: authorization } },
        auth: { persistSession: false, autoRefreshToken: false },
      })
      const { data, error } = await userClient.auth.getUser()
      if (error) {
        console.error('[consent] getUser:', error.message)
      } else {
        userId = data.user?.id ?? null
      }
    } catch (error) {
      console.error('[consent] optional auth failed', error)
    }
  }

  const salt = Deno.env.get('CONSENT_IP_SALT')
  if (!salt) {
    console.error('[consent] CONSENT_IP_SALT is not set — using fallback (configure the secret)')
  }
  const ipHash = await sha256Hex(`${clientIp(req)}|${salt || 'domio-consent-salt-unconfigured'}`)
  const userAgent = (req.headers.get('user-agent') ?? 'unknown').slice(0, 512)

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })

  const { error: insertError } = await admin.from('cookie_consents').insert({
    consent_id: payload.consentId,
    user_id: userId,
    accepted_categories: payload.categories,
    policy_version: payload.policyVersion,
    action: payload.action,
    app_source: payload.appSource,
    ip_address_hash: ipHash,
    user_agent: userAgent,
  })

  if (insertError) {
    console.error('[consent] insert failed', insertError)
    return json(cors, 500, { error: 'INSERT_FAILED' })
  }

  return json(cors, 201, { ok: true })
})
