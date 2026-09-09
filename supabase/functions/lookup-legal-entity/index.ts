import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import { fetchGusByNip } from './gusBir.ts'

const ALLOWED_ORIGINS = [
  'https://cleaning.domio.com.pl',
  'https://test.cleaning.domio.com.pl',
  'https://serwis.domio.com.pl',
  'https://test.serwis.domio.com.pl',
  'https://admin.domio.com.pl',
  'https://test.admin.domio.com.pl',
  'https://home.domio.com.pl',
  'https://test.home.domio.com.pl',
  'https://domio.com.pl',
  'http://localhost:5173',
  'http://localhost:8080',
  'http://127.0.0.1:5173',
  'http://127.0.0.1:8080',
]

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

function digitsNip(raw: unknown): string {
  return String(raw ?? '').replace(/\D/g, '')
}

function optionalUuid(raw: unknown): string | null {
  const value = String(raw ?? '').trim()
  if (!value || value === 'null' || value === 'undefined') return null
  return value
}

function userClient(req: Request) {
  const url = Deno.env.get('SUPABASE_URL')
  const anon = Deno.env.get('SUPABASE_ANON_KEY')
  if (!url || !anon) throw new Error('Missing server configuration')
  return createClient(url, anon, {
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
    auth: { persistSession: false, autoRefreshToken: false },
  })
}

function rpcError(error: { message?: string; details?: string } | null): string {
  const msg = `${error?.message ?? ''} ${error?.details ?? ''}`
  const token = msg.match(/[A-Z_]+_([A-Z_]+)/)?.[0] ?? error?.message ?? 'RPC_FAILED'
  return token
}

Deno.serve(async function (req) {
  const cors = getCorsHeaders(req)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors })
  }
  if (req.method !== 'POST') {
    return json(cors, 405, { error: 'Method not allowed' })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.toLowerCase().startsWith('bearer ')) {
    return json(cors, 401, { error: 'Unauthorized' })
  }

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json(cors, 400, { error: 'Invalid request body' })
  }

  const action = String(body.action ?? 'lookup')
  const orgId = String(body.orgId ?? body.org_id ?? '')
  const supabase = userClient(req)

  try {
    if (action === 'lookup') {
      const nip = digitsNip(body.nip)
      const { data, error } = await supabase.rpc('lookup_legal_entity_by_nip', {
        p_nip: nip,
        p_org_id: orgId,
      })
      if (error) return json(cors, 403, { error: rpcError(error), details: error.message })

      const lookup = data as {
        status?: string
        entity?: unknown
        alreadyEnrolledInThisOrg?: boolean
      }
      if (lookup?.status !== 'not_in_domio') {
        return json(cors, 200, lookup)
      }

      try {
        const gus = await fetchGusByNip(nip)
        if (!gus.preview) {
          return json(cors, 200, {
            status: 'not_in_gus',
            entity: null,
            gusPreview: null,
            alreadyEnrolledInThisOrg: false,
          })
        }
        if (gus.preview.endedAt) {
          return json(cors, 200, {
            status: 'gus_inactive',
            entity: null,
            gusPreview: gus.preview,
            suggestedKind: gus.suggestedKind,
            alreadyEnrolledInThisOrg: false,
          })
        }
        return json(cors, 200, {
          status: 'found_in_gus',
          entity: null,
          gusPreview: gus.preview,
          suggestedKind: gus.suggestedKind,
          alreadyEnrolledInThisOrg: false,
        })
      } catch (gusError) {
        const code = gusError instanceof Error ? gusError.message : 'GUS_FAILED'
        if (code === 'GUS_NOT_CONFIGURED') {
          return json(cors, 503, { error: 'GUS_NOT_CONFIGURED', status: 'not_in_domio' })
        }
        return json(cors, 502, { error: code, status: 'not_in_domio' })
      }
    }

    if (action === 'enroll') {
      const { data, error } = await supabase.rpc('enroll_legal_entity_for_org', {
        p_org_id: orgId,
        p_legal_entity_id: String(body.legalEntityId ?? body.legal_entity_id ?? ''),
        p_is_cleaning: body.isCleaning === true,
        p_is_maintenance: body.isMaintenance === true,
        p_is_admin: body.isAdmin === true,
      })
      if (error) return json(cors, 400, { error: rpcError(error), details: error.message })
      return json(cors, 200, data)
    }

    if (action === 'create') {
      const nip = digitsNip(body.nip)
      const gus = await fetchGusByNip(nip)
      if (!gus.preview) {
        return json(cors, 400, { error: 'NOT_IN_GUS' })
      }
      if (gus.preview.endedAt) {
        return json(cors, 400, { error: 'GUS_INACTIVE' })
      }
      const kind = String(body.kind ?? gus.suggestedKind)
      const { data, error } = await supabase.rpc('create_legal_entity_from_gus', {
        p_org_id: orgId,
        p_kind: kind,
        p_gus: {
          ...gus.preview,
          buildingNumber: body.buildingNumber ?? gus.preview.buildingNumber,
        },
        p_email: String(body.email ?? ''),
        p_phone: String(body.phone ?? ''),
        p_short_name: String(body.shortName ?? body.short_name ?? ''),
        p_is_cleaning: body.isCleaning === true,
        p_is_maintenance: body.isMaintenance === true,
        p_is_admin: body.isAdmin === true,
      })
      if (error) return json(cors, 400, { error: rpcError(error), details: error.message })
      return json(cors, 201, data)
    }

    if (action === 'attachBuilding') {
      const { data, error } = await supabase.rpc('attach_legal_entity_to_building', {
        p_org_id: orgId,
        p_cleaning_location_id: String(body.cleaningLocationId ?? body.cleaning_location_id ?? ''),
        p_legal_entity_id: String(body.legalEntityId ?? body.legal_entity_id ?? ''),
      })
      if (error) {
        const code = rpcError(error)
        if (code.includes('ADDRESS_OWNED_BY_OTHER_ENTITY')) {
          let owner: unknown = null
          try {
            owner = JSON.parse(error.details ?? '{}')
          } catch {
            owner = error.details ?? null
          }
          return json(cors, 409, { error: 'ADDRESS_OWNED_BY_OTHER_ENTITY', owner })
        }
        return json(cors, 400, { error: code, details: error.message })
      }
      return json(cors, 200, data)
    }

    if (action === 'enrollBuilding') {
      const { data, error } = await supabase.rpc('enroll_building_for_legal_entity', {
        p_org_id: orgId,
        p_legal_entity_id: optionalUuid(body.legalEntityId ?? body.legal_entity_id),
        p_google_place_id: String(body.googlePlaceId ?? body.google_place_id ?? ''),
        p_address: String(body.address ?? ''),
        p_latitude: typeof body.latitude === 'number' ? body.latitude : null,
        p_longitude: typeof body.longitude === 'number' ? body.longitude : null,
        p_module: String(body.module ?? ''),
      })
      if (error) {
        const code = rpcError(error)
        if (code.includes('ADDRESS_OWNED_BY_OTHER_ENTITY')) {
          let owner: unknown = null
          try {
            owner = JSON.parse(error.details ?? '{}')
          } catch {
            owner = error.details ?? null
          }
          return json(cors, 409, { error: 'ADDRESS_OWNED_BY_OTHER_ENTITY', owner })
        }
        return json(cors, 400, { error: code, details: error.message })
      }
      return json(cors, 200, data)
    }

    if (action === 'adminCreate') {
      const { data, error } = await supabase.rpc('platform_admin_create_legal_entity_without_gus', {
        p_kind: String(body.kind ?? 'company'),
        p_nip: digitsNip(body.nip),
        p_regon: String(body.regon ?? ''),
        p_krs: body.krs ? String(body.krs) : null,
        p_short_name: String(body.shortName ?? ''),
        p_legal_name: String(body.legalName ?? ''),
        p_voivodeship: String(body.voivodeship ?? ''),
        p_county: body.county ? String(body.county) : null,
        p_commune: body.commune ? String(body.commune) : null,
        p_city: String(body.city ?? ''),
        p_postal_code: String(body.postalCode ?? ''),
        p_street: body.street ? String(body.street) : null,
        p_building_number: String(body.buildingNumber ?? ''),
        p_apartment_number: body.apartmentNumber ? String(body.apartmentNumber) : null,
        p_seat_full_address: String(body.seatFullAddress ?? ''),
        p_email: String(body.email ?? ''),
        p_phone: String(body.phone ?? ''),
      })
      if (error) return json(cors, 400, { error: rpcError(error), details: error.message })
      return json(cors, 201, data)
    }

    return json(cors, 400, { error: 'UNKNOWN_ACTION' })
  } catch (err) {
    const code = err instanceof Error ? err.message : 'INTERNAL_ERROR'
    if (code === 'GUS_NOT_CONFIGURED') {
      return json(cors, 503, { error: 'GUS_NOT_CONFIGURED' })
    }
    return json(cors, 500, { error: code })
  }
})
