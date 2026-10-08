import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import {
  blockedComment,
  buildCommentBody,
  decideComment,
  readyComment,
  unavailableComment,
  type CommentDecision,
} from '../_shared/jevComment.ts'

const ALLOWED_ORIGINS = [
  'https://home.domio.com.pl',
  'https://test.home.domio.com.pl',
  'https://admin.domio.com.pl',
  'https://test.admin.domio.com.pl',
  'https://adm.domio.com.pl',
  'https://test.adm.domio.com.pl',
]

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

const MAX_CONTENT = 2000

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

type CommentBody = {
  postId: string
  content: string
}

function parseBody(raw: unknown): CommentBody | null {
  if (!raw || typeof raw !== 'object') return null
  const row = raw as Record<string, unknown>
  const postId = typeof row.post_id === 'string' ? row.post_id.trim() : ''
  const content = typeof row.content === 'string' ? row.content.trim() : ''
  if (!UUID_RE.test(postId)) return null
  if (content.length < 1 || content.length > MAX_CONTENT) return null
  return { postId, content }
}

async function classify(content: string): Promise<CommentDecision> {
  const apiKey = Deno.env.get('TYPESAFE_API_KEY')?.trim()
  if (!apiKey) {
    console.error('[verify-comment] TYPESAFE_API_KEY is not set')
    return unavailableComment()
  }

  try {
    const response = await fetch('https://api.typesafe.ai/v1/systemone', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(buildCommentBody(content)),
      signal: AbortSignal.timeout(8000),
    })
    if (!response.ok) {
      console.error('[verify-comment] Jev status', response.status)
      return unavailableComment()
    }
    return decideComment(content, await response.json())
  } catch (error) {
    console.error('[verify-comment] Jev request failed', error)
    return unavailableComment()
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
      console.error('[verify-comment] Missing Supabase env')
      return json(cors, 500, { error: 'Server misconfiguration' })
    }

    const accessToken = authHeader.slice('Bearer '.length).trim()
    if (!accessToken) return json(cors, 401, { error: 'Unauthorized' })

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    })
    const { data: userData, error: userError } = await userClient.auth.getUser(accessToken)
    if (userError || !userData.user) {
      console.error('[verify-comment] auth', userError?.message ?? 'missing user')
      return json(cors, 401, { error: 'Unauthorized' })
    }

    let raw: unknown
    try {
      raw = await req.json()
    } catch (error) {
      console.error('[verify-comment] Invalid JSON', error)
      return json(cors, 400, { error: 'Invalid JSON body' })
    }
    const body = parseBody(raw)
    if (!body) return json(cors, 400, { error: 'Invalid comment payload' })

    const { data: post, error: postError } = await userClient
      .from('community_board')
      .select('id, org_id, status')
      .eq('id', body.postId)
      .maybeSingle()
    if (postError || !post?.org_id || post.status !== 'active') {
      console.error('[verify-comment] post access', postError?.message ?? 'denied')
      return json(cors, 403, { error: 'Forbidden' })
    }

    const lexiconDecision = decideComment(body.content, null)
    if (lexiconDecision.outcome === 'blocked') {
      return json(cors, 200, { decision: blockedComment('PROFANITY'), comment_id: null })
    }

    let decision = await classify(body.content)
    if (decision.outcome === 'unavailable') {
      console.error('[verify-comment] classifier unavailable, publishing lexicon-clean comment')
      decision = readyComment()
    }
    if (decision.outcome !== 'ready') {
      return json(cors, 200, { decision, comment_id: null })
    }

    const admin = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })
    const { data: inserted, error: insertError } = await admin
      .from('community_comments')
      .insert({
        post_id: body.postId,
        content: body.content,
        author_id: userData.user.id,
        org_id: post.org_id,
      })
      .select('id')
      .single()

    if (insertError || !inserted) {
      console.error('[verify-comment] insert', insertError?.message ?? 'empty')
      if (insertError?.message?.includes('wulgaryzmy')) {
        return json(cors, 200, { decision: blockedComment('PROFANITY'), comment_id: null })
      }
      return json(cors, 500, { error: 'Insert failed' })
    }

    return json(cors, 200, { decision, comment_id: inserted.id })
  } catch (error) {
    console.error('[verify-comment] Unhandled', error)
    return json(cors, 500, { error: 'Internal server error' })
  }
})
