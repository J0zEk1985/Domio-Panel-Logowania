import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

/**
 * Edge Function: create-worker
 * Accepts: slug, pin, firstName, lastName, orgId
 * Returns: userId, email
 * Gateway verify_jwt stays false. Caller JWT is required inside.
 */

const ALLOWED_ORIGINS = [
  'https://cleaning.domio.com.pl',
  'https://test.cleaning.domio.com.pl',
  'https://serwis.domio.com.pl',
  'https://test.serwis.domio.com.pl',
  'https://admin.domio.com.pl',
  'https://test.admin.domio.com.pl',
  'http://localhost:5173',
  'http://localhost:8080',
  'http://127.0.0.1:5173',
  'http://127.0.0.1:8080',
]

function getCorsHeaders(req) {
  const origin = req.headers.get('Origin') ?? ''
  const allowOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0]
  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Vary': 'Origin',
  }
}

function json(corsHeaders, status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function buildSlug(firstName, lastName) {
  const normalize = (s) =>
    String(s || '')
      .toLowerCase()
      .replace(/ą/g, 'a')
      .replace(/ć/g, 'c')
      .replace(/ę/g, 'e')
      .replace(/ł/g, 'l')
      .replace(/ń/g, 'n')
      .replace(/ó/g, 'o')
      .replace(/ś/g, 's')
      .replace(/ź|ż/g, 'z')
      .replace(/[^a-z0-9]+/g, '')
  const initial = normalize(firstName)[0] || ''
  const lastPart = normalize(lastName)
  return initial && lastPart ? `${initial}.${lastPart}` : ''
}

function splitFullName(fullName) {
  const parts = String(fullName || '').trim().split(/\s+/).filter(Boolean)
  if (parts.length === 0) return { firstName: '', lastName: '' }
  if (parts.length === 1) return { firstName: parts[0], lastName: parts[0] }
  return { firstName: parts[0], lastName: parts.slice(1).join(' ') }
}

function normalizeCreateWorkerBody(raw) {
  const orgId = raw.orgId || raw.org_id
  const pin = raw.pin
  const fromFull = splitFullName(raw.full_name || raw.fullName)
  const firstName = String(raw.firstName || raw.first_name || fromFull.firstName || '').trim()
  const lastName = String(raw.lastName || raw.last_name || fromFull.lastName || '').trim()
  const slug = String(raw.slug || raw.login || '').trim() || buildSlug(firstName, lastName)
  return Object.assign({}, raw, { orgId, pin, firstName, lastName, slug })
}

async function resolveUniqueSlug(client, baseSlug) {
  const normalized =
    String(baseSlug || '')
      .toLowerCase()
      .replace(/[^a-z0-9.]/g, '')
      .replace(/^\.+|\.+$/g, '') || 'user'
  for (let n = 0; n < 100; n++) {
    const candidate = n === 0 ? normalized : `${normalized}${n}`
    const { data, error } = await client.rpc('check_slug_available', { p_slug: candidate })
    if (error) return `${normalized}${Math.floor(Math.random() * 9000) + 1000}`
    if (data === true) return candidate
  }
  return `${normalized}${Date.now().toString().slice(-4)}`
}

function resolveMembershipRole(raw) {
  const allowed = new Set([
    'cleaner',
    'technik',
    'koordynator',
    'wlasciciel',
    'coordinator',
    'owner',
    'admin',
    'administrator',
    'manager',
  ])
  const role = String(raw ?? '').trim().toLowerCase()
  if (allowed.has(role)) return role
  return 'cleaner'
}

async function ensureMembership(client, userId, orgId, extras) {
  const role = resolveMembershipRole(extras && extras.role)
  const specializations = Array.isArray(extras && extras.specializations) ? extras.specializations : []
  const requireGps = extras && extras.requireGpsValidation === true
  const { data: existing } = await client
    .from('memberships')
    .select('id')
    .eq('user_id', userId)
    .eq('org_id', orgId)
    .maybeSingle()
  if (existing?.id) {
    const { error } = await client
      .from('memberships')
      .update({
        role,
        is_active: true,
        specializations,
        require_gps_validation: requireGps,
      })
      .eq('id', existing.id)
    return { error: error ?? null }
  }
  const { error } = await client.from('memberships').insert({
    user_id: userId,
    org_id: orgId,
    role,
    is_active: true,
    specializations,
    require_gps_validation: requireGps,
  })
  return { error: error ?? null }
}

Deno.serve(async function (req) {
  const corsHeaders = getCorsHeaders(req)
  console.log('[create-worker]', req.method, req.headers.get('Origin'))

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    if (!supabaseUrl || !serviceRoleKey) {
      return json(corsHeaders, 500, { error: 'Missing server configuration' })
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    })

    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.toLowerCase().startsWith('bearer ')) {
      return json(corsHeaders, 401, { error: 'Unauthorized' })
    }
    const callerJwt = authHeader.slice(7).trim()
    const { data: callerData, error: callerError } = await supabaseAdmin.auth.getUser(callerJwt)
    if (callerError || !callerData.user?.id) {
      return json(corsHeaders, 401, { error: 'Unauthorized' })
    }

    let body
    try {
      body = await req.json()
    } catch (parseError) {
      return json(corsHeaders, 400, {
        error: 'Invalid request body',
        details: parseError instanceof Error ? parseError.message : 'Unknown error',
      })
    }

    body = normalizeCreateWorkerBody(body)

    if (!body.slug || !body.pin || !body.firstName || !body.lastName || !body.orgId) {
      return json(corsHeaders, 400, {
        error: 'Missing required fields: slug, pin, firstName, lastName, orgId',
      })
    }

    const { data: orgRow, error: orgCheckError } = await supabaseAdmin
      .from('organizations')
      .select('id')
      .eq('id', body.orgId)
      .maybeSingle()

    if (orgCheckError) {
      return json(corsHeaders, 500, { error: 'Organization lookup failed', details: orgCheckError.message })
    }
    if (!orgRow?.id) {
      return json(corsHeaders, 400, { error: 'Organization not found', details: 'Invalid orgId' })
    }

    body.slug = await resolveUniqueSlug(supabaseAdmin, body.slug)

    const { data: callerMemberships, error: callerMembershipError } = await supabaseAdmin
      .from('memberships')
      .select('role, is_active')
      .eq('user_id', callerData.user.id)
      .eq('org_id', body.orgId)

    const managementRoles = new Set([
      'owner',
      'admin',
      'administrator',
      'coordinator',
      'koordynator',
      'manager',
      'wlasciciel',
      'właściciel',
    ])
    const canManageWorkers = (callerMemberships ?? []).some(function (m) {
      const role = String(m.role ?? '').trim().toLowerCase()
      return m.is_active !== false && managementRoles.has(role)
    })
    if (callerMembershipError || !canManageWorkers) {
      return json(corsHeaders, 403, { error: 'Forbidden' })
    }

    const technicalEmail = `${String(body.slug).toLowerCase()}@staff.domio.com.pl`
    const fullName = `${body.firstName} ${body.lastName}`

    const membershipExtras = {
      role: body.membershipRole || body.role || 'cleaner',
      specializations: body.specializations,
      requireGpsValidation: body.requireGpsValidation === true || body.require_gps_validation === true,
    }
    const phone =
      typeof body.phone === 'string' && body.phone.trim() ? body.phone.trim() : null

    const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: technicalEmail,
      password: body.pin,
      email_confirm: true,
      user_metadata: {
        firstName: body.firstName,
        lastName: body.lastName,
        is_simplified: true,
      },
    })

    let userId
    let isNewUser = false

    if (authError) {
      const errorMessage = authError.message?.toLowerCase() || ''
      const exists =
        errorMessage.includes('already registered') ||
        errorMessage.includes('user already exists') ||
        errorMessage.includes('already exists') ||
        errorMessage.includes('email address is already registered')
      if (!exists) {
        return json(corsHeaders, 500, { error: 'Failed to create user account', details: authError.message })
      }

      const { data: existingProfile, error: profileFetchError } = await supabaseAdmin
        .from('profiles')
        .select('id')
        .eq('email', technicalEmail)
        .maybeSingle()

      if (profileFetchError) {
        return json(corsHeaders, 500, {
          error: 'User exists but profile lookup failed',
          details: profileFetchError?.message || 'Profile lookup failed',
        })
      }

      if (!existingProfile?.id) {
        const { data: usersList, error: listError } = await supabaseAdmin.auth.admin.listUsers()
        if (listError) {
          return json(corsHeaders, 500, {
            error: 'User exists but profile lookup failed',
            details: 'Could not retrieve user ID from auth',
          })
        }
        const existingUser = usersList?.users?.find(function (u) { return u.email === technicalEmail })
        if (!existingUser?.id) {
          return json(corsHeaders, 500, {
            error: 'User exists but user ID not found',
            details: 'Profile record missing for existing user',
          })
        }
        userId = existingUser.id
      } else {
        userId = existingProfile.id
      }

      const { data: existingProfileFull, error: profileTypeError } = await supabaseAdmin
        .from('profiles')
        .select('id, account_type')
        .eq('id', userId)
        .maybeSingle()

      if (!profileTypeError && existingProfileFull?.account_type) {
        const at = String(existingProfileFull.account_type).toLowerCase()
        if (at === 'standard' || at === 'hub') {
          const { error: membErr } = await ensureMembership(supabaseAdmin, userId, body.orgId, membershipExtras)
          if (membErr) {
            return json(corsHeaders, 500, { error: 'Failed to ensure membership', details: membErr.message })
          }
          return json(corsHeaders, 200, {
            userId,
            email: technicalEmail,
            login: String(body.slug).toLowerCase(),
            message: 'Membership ensured for existing standard account',
          })
        }
      }
    } else if (!authUser?.user) {
      return json(corsHeaders, 500, { error: 'Failed to create user account', details: 'No user data returned' })
    } else {
      userId = authUser.user.id
      isNewUser = true
    }

    const acceptedTermsAt = new Date().toISOString()
    const { error: profileError } = await supabaseAdmin.from('profiles').upsert(
      {
        id: userId,
        full_name: fullName,
        email: technicalEmail,
        phone,
        accepted_terms_at: acceptedTermsAt,
        terms_version: '1.0',
        account_type: 'simplified',
        is_first_login: true,
        preferences: {
          firstName: body.firstName,
          lastName: body.lastName,
          orgId: body.orgId,
          is_simplified: true,
        },
      },
      { onConflict: 'id' },
    )

    if (profileError) {
      if (isNewUser) await supabaseAdmin.auth.admin.deleteUser(userId)
      return json(corsHeaders, 500, { error: 'Failed to create user profile', details: profileError.message })
    }

    const { error: membErr } = await ensureMembership(supabaseAdmin, userId, body.orgId, membershipExtras)
    if (membErr) {
      if (isNewUser) await supabaseAdmin.auth.admin.deleteUser(userId)
      return json(corsHeaders, 500, { error: 'Failed to create membership', details: membErr.message })
    }

    return json(corsHeaders, 201, {
      success: true,
      userId,
      email: technicalEmail,
      login: String(body.slug).toLowerCase(),
      message: 'Worker account created successfully',
    })
  } catch (error) {
    return json(corsHeaders, 500, {
      error: 'Internal server error',
      details: error instanceof Error ? error.message : 'Unknown error',
    })
  }
})
