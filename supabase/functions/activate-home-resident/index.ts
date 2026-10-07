import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

/**
 * First visit of a resident email on DOMIO Home.
 * Creates a home account only when the address is on a unit register,
 * then asks GoTrue to mail a one-time password link.
 * Gateway verify_jwt stays false. No caller session is required.
 */

const ALLOWED_ORIGINS = [
  'https://home.domio.com.pl',
  'https://test.home.domio.com.pl',
  'http://localhost:8080',
  'http://127.0.0.1:8080',
  'http://localhost:8081',
  'http://127.0.0.1:8081',
  'http://localhost:5173',
  'http://127.0.0.1:5173',
]

const EMAIL_PATTERN = /^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$/
const FULL_ACCOUNT_TYPES = new Set(['hub', 'standard', 'full'])

type ActivateStatus = 'unknown' | 'login' | 'activation_sent' | 'reset_sent' | 'rejected'

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

function normalizeEmail(value: unknown): string {
  return String(value ?? '').trim().toLowerCase()
}

function randomPassword(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%'
  const bytes = new Uint8Array(24)
  crypto.getRandomValues(bytes)
  return Array.from(bytes, (byte) => chars[byte % chars.length]).join('')
}

async function findAuthUserId(admin: SupabaseClient, email: string): Promise<string | null> {
  const { data, error } = await admin.rpc('auth_user_id_by_email', { p_email: email })
  if (error) {
    console.error('[activate-home-resident] auth_user_id_by_email:', error)
    throw new Error('lookup_failed')
  }
  return typeof data === 'string' && data.length > 0 ? data : null
}

async function sendPasswordLink(supabaseUrl: string, serviceRoleKey: string, email: string): Promise<void> {
  const redirectTo = Deno.env.get('HOME_PASSWORD_REDIRECT_URL')?.trim() || 'https://home.domio.com.pl/ustaw-haslo'
  const url = new URL(`${supabaseUrl.replace(/\/$/, '')}/auth/v1/recover`)
  url.searchParams.set('redirect_to', redirectTo)
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
    },
    body: JSON.stringify({ email }),
  })
  if (!response.ok) {
    const detail = await response.text()
    console.error('[activate-home-resident] recover:', response.status, detail)
    throw new Error(response.status === 429 ? 'rate_limited' : 'mail_failed')
  }
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

  let body: Record<string, unknown>
  try {
    body = (await req.json()) as Record<string, unknown>
  } catch (error) {
    console.error('[activate-home-resident] body:', error)
    return json(cors, 400, { error: 'Nieprawidłowe ciało żądania.' })
  }

  const email = normalizeEmail(body.email)
  const intent = String(body.intent ?? 'activate').trim().toLowerCase() === 'reset' ? 'reset' : 'activate'
  if (!EMAIL_PATTERN.test(email)) {
    return json(cors, 400, { status: 'unknown' as ActivateStatus, error: 'Podaj poprawny adres e-mail.' })
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  try {
    const { data: occupants, error: occupantError } = await admin
      .from('community_unit_occupants')
      .select('full_name')
      .eq('email', email)
      .limit(1)

    if (occupantError) {
      console.error('[activate-home-resident] occupants:', occupantError)
      return json(cors, 500, { error: 'Nie udało się sprawdzić rejestru mieszkańców.' })
    }

    const fullName = String(occupants?.[0]?.full_name ?? '').trim()
    if (!fullName) {
      return json(cors, 200, { status: 'unknown' as ActivateStatus })
    }

    let userId = await findAuthUserId(admin, email)
    let createdUser = false

    const { data: profileRows, error: profileError } = await admin
      .from('profiles')
      .select('id, account_type, home_password_set_at, full_name')
      .eq('email', email)
      .order('updated_at', { ascending: false })
      .limit(1)

    if (profileError) {
      console.error('[activate-home-resident] profile:', profileError)
      return json(cors, 500, { error: 'Nie udało się sprawdzić konta.' })
    }

    const profile = profileRows?.[0] ?? null
    if (!userId && profile?.id) userId = profile.id
    if (profile?.id && userId && profile.id !== userId) {
      console.error('[activate-home-resident] profile/auth mismatch', profile.id, userId)
      return json(cors, 500, { error: 'Konto z tym e-mailem jest niespójne. Skontaktuj się z administracją.' })
    }

    const accountType = String(profile?.account_type ?? '').trim().toLowerCase()
    if (accountType === 'simplified') {
      return json(cors, 200, {
        status: 'rejected' as ActivateStatus,
        error: 'To konto pracownika. Zaloguj się loginem nadanym przez przełożonego.',
      })
    }

    const passwordReady = accountType === 'home' && profile?.home_password_set_at
    if (FULL_ACCOUNT_TYPES.has(accountType) || passwordReady) {
      if (intent === 'reset') {
        await sendPasswordLink(supabaseUrl, serviceRoleKey, email)
        return json(cors, 200, { status: 'reset_sent' as ActivateStatus })
      }
      return json(cors, 200, { status: 'login' as ActivateStatus })
    }

    if (!userId) {
      const { data: created, error: createError } = await admin.auth.admin.createUser({
        email,
        password: randomPassword(),
        email_confirm: true,
        user_metadata: { full_name: fullName },
      })
      if (createError || !created.user?.id) {
        const message = createError?.message?.toLowerCase() ?? ''
        const exists = message.includes('already') || message.includes('registered')
        if (!exists) {
          console.error('[activate-home-resident] createUser:', createError)
          return json(cors, 500, { error: 'Nie udało się utworzyć konta.' })
        }
        userId = await findAuthUserId(admin, email)
        if (!userId) {
          return json(cors, 500, { error: 'Nie udało się utworzyć konta.' })
        }
      } else {
        userId = created.user.id
        createdUser = true
      }
    }

    if (!profile || accountType === '' || accountType === 'home') {
      const row = {
        id: userId,
        email,
        full_name: fullName || profile?.full_name || email,
        account_type: 'home',
        is_first_login: false,
      }
      const { error: saveError } = profile
        ? await admin.from('profiles').update({
            email: row.email,
            full_name: row.full_name,
            account_type: 'home',
            is_first_login: false,
          }).eq('id', userId)
        : await admin.from('profiles').insert(row)

      if (saveError) {
        console.error('[activate-home-resident] profile save:', saveError)
        if (createdUser) await admin.auth.admin.deleteUser(userId)
        return json(cors, 500, { error: 'Nie udało się zapisać profilu mieszkańca.' })
      }
    }

    await sendPasswordLink(supabaseUrl, serviceRoleKey, email)
    return json(cors, 200, {
      status: (intent === 'reset' ? 'reset_sent' : 'activation_sent') as ActivateStatus,
    })
  } catch (error) {
    console.error('[activate-home-resident]', error)
    const code = error instanceof Error ? error.message : ''
    if (code === 'rate_limited') {
      return json(cors, 429, { error: 'Odczekaj chwilę i spróbuj wysłać link ponownie.' })
    }
    if (code === 'mail_failed') {
      return json(cors, 502, { error: 'Nie udało się wysłać wiadomości. Spróbuj ponownie.' })
    }
    return json(cors, 500, { error: 'Nie udało się przygotować konta.' })
  }
})
