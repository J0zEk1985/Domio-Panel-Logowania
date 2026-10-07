import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import {
  buildAnnouncementBody,
  heldDecision,
  mapAnnouncementResponse,
  type AnnouncementDecision,
} from '../_shared/jevAnnouncement.ts'

const ALLOWED_ORIGINS = [
  'https://home.domio.com.pl',
  'https://test.home.domio.com.pl',
  'https://admin.domio.com.pl',
  'https://test.admin.domio.com.pl',
  'https://adm.domio.com.pl',
  'https://test.adm.domio.com.pl',
]

const POST_TYPES = new Set(['request', 'event', 'general', 'offer'])
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

function corsHeaders(req: Request) {
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

type PublishBody = {
  mode: 'preview' | 'publish'
  title: string
  content: string
  postType: 'request' | 'event' | 'general' | 'offer'
  isFree: boolean
  price: number | null
  locationId: string
}

function parseBody(raw: unknown): PublishBody | null {
  if (!raw || typeof raw !== 'object') return null
  const row = raw as Record<string, unknown>
  const mode = row.mode === 'publish' ? 'publish' : row.mode === 'preview' ? 'preview' : null
  const title = typeof row.title === 'string' ? row.title.trim() : ''
  const content = typeof row.content === 'string' ? row.content.trim() : ''
  const postType = typeof row.post_type === 'string' ? row.post_type : ''
  const locationId = typeof row.location_id === 'string' ? row.location_id.trim() : ''
  const isFree = row.is_free === true
  const priceRaw = row.price
  const price = typeof priceRaw === 'number' && Number.isFinite(priceRaw) ? priceRaw : null
  if (!mode || !POST_TYPES.has(postType) || !UUID_RE.test(locationId)) return null
  if (title.length < 1 || title.length > 150) return null
  if (content.length < 1 || content.length > 4000) return null
  if (postType === 'offer' && !isFree && (price === null || price < 0)) return null
  return {
    mode,
    title,
    content,
    postType: postType as PublishBody['postType'],
    isFree: postType === 'offer' ? isFree : false,
    price: postType === 'offer' && !isFree ? price : null,
    locationId,
  }
}

async function classify(title: string, content: string): Promise<AnnouncementDecision> {
  const apiKey = Deno.env.get('TYPESAFE_API_KEY')?.trim()
  if (!apiKey) {
    console.error('[verify-announcement] TYPESAFE_API_KEY is not set')
    return heldDecision('jev_unavailable')
  }

  try {
    const response = await fetch('https://api.typesafe.ai/v1/systemone', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(buildAnnouncementBody(title, content)),
      signal: AbortSignal.timeout(8000),
    })
    if (!response.ok) {
      console.error('[verify-announcement] Jev status', response.status)
      return heldDecision('jev_unavailable')
    }
    const payload = await response.json()
    return mapAnnouncementResponse(payload)
  } catch (error) {
    console.error('[verify-announcement] Jev request failed', error)
    return heldDecision('jev_unavailable')
  }
}

Deno.serve(async (req) => {
  const cors = corsHeaders(req)
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  if (req.method !== 'POST') return json(cors, 405, { error: 'Method not allowed' })

  try {
    const authHeader = req.headers.get('Authorization') ?? ''
    if (!authHeader.startsWith('Bearer ')) return json(cors, 401, { error: 'Unauthorized' })

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    if (!supabaseUrl || !anonKey || !serviceKey) {
      console.error('[verify-announcement] Missing Supabase env')
      return json(cors, 500, { error: 'Server misconfiguration' })
    }

    const accessToken = authHeader.slice('Bearer '.length).trim()
    if (!accessToken) return json(cors, 401, { error: 'Unauthorized' })

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    })
    // getUser() without a JWT reads only the local session. This client has none,
    // so the caller token must be passed explicitly or every request returns 401.
    const { data: userData, error: userError } = await userClient.auth.getUser(accessToken)
    if (userError || !userData.user) {
      console.error('[verify-announcement] auth', userError?.message ?? 'missing user')
      return json(cors, 401, { error: 'Unauthorized' })
    }

    let raw: unknown
    try {
      raw = await req.json()
    } catch (error) {
      console.error('[verify-announcement] Invalid JSON', error)
      return json(cors, 400, { error: 'Invalid JSON body' })
    }
    const body = parseBody(raw)
    if (!body) return json(cors, 400, { error: 'Invalid announcement payload' })

    const { data: allowed, error: accessError } = await userClient.rpc('has_active_location_access', {
      target_location_id: body.locationId,
    })
    if (accessError || allowed !== true) {
      console.error('[verify-announcement] location access', accessError?.message ?? 'denied')
      return json(cors, 403, { error: 'Forbidden' })
    }

    const { data: location, error: locationError } = await userClient
      .from('cleaning_locations')
      .select('id, org_id')
      .eq('id', body.locationId)
      .maybeSingle()
    if (locationError || !location?.org_id) {
      console.error('[verify-announcement] location lookup', locationError?.message ?? 'missing')
      return json(cors, 403, { error: 'Forbidden' })
    }

    const decision = await classify(body.title, body.content)
    if (body.mode === 'preview' || decision.outcome === 'blocked') {
      return json(cors, 200, { decision, post_id: null })
    }

    const status = decision.outcome === 'ready' ? 'active' : 'pending_review'
    const admin = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })
    const { data: inserted, error: insertError } = await admin
      .from('community_board')
      .insert({
        org_id: location.org_id,
        location_id: body.locationId,
        author_id: userData.user.id,
        title: body.title,
        content: body.content,
        post_type: body.postType,
        status,
        is_free: body.isFree,
        price: body.price,
        moderation_hold: decision.hold,
      })
      .select('id')
      .single()

    if (insertError || !inserted) {
      console.error('[verify-announcement] insert', insertError?.message ?? 'empty')
      return json(cors, 500, { error: 'Insert failed' })
    }

    return json(cors, 200, { decision, post_id: inserted.id })
  } catch (error) {
    console.error('[verify-announcement] Unhandled', error)
    return json(cors, 500, { error: 'Internal server error' })
  }
})
