import { supabase } from './supabase'
import {
  billingNipErrorMessage,
  type BillingGusPreview,
} from './billingNipLookup'
import type { LegalEntityKind } from './legalEntityMessages'

type RpcClient = {
  rpc: (
    fn: string,
    args?: Record<string, unknown>,
  ) => Promise<{ data: unknown; error: { message: string } | null }>
}

function rpcClient(): RpcClient {
  return supabase as unknown as RpcClient
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, unknown>
  }
  return null
}

export type UpsertBillingLegalEntityResult = {
  ok: boolean
  status?: string
  legalEntityId: string | null
  listed: boolean
  error?: string
}

export class BillingOrgLegalEntityError extends Error {
  readonly code: string
  constructor(code: string) {
    super(billingNipErrorMessage(code))
    this.name = 'BillingOrgLegalEntityError'
    this.code = code
  }
}

export async function upsertBillingOrgLegalEntity(input: {
  orgId: string
  nip: string
  legalName: string
  city: string
  postalCode: string
  address: string
  phone: string
  gus: BillingGusPreview | null
  kind?: LegalEntityKind
  listedInProviderDirectory: boolean
}): Promise<UpsertBillingLegalEntityResult> {
  const { data, error } = await rpcClient().rpc('upsert_billing_org_legal_entity', {
    p_org_id: input.orgId,
    p_nip: input.nip,
    p_legal_name: input.legalName,
    p_city: input.city,
    p_postal_code: input.postalCode,
    p_address: input.address,
    p_phone: input.phone,
    p_gus: input.gus,
    p_kind: input.kind ?? 'company',
    p_listed_in_provider_directory: input.listedInProviderDirectory,
  })
  if (error) {
    console.error('[billingOrgLegalEntity] upsert:', error)
    throw new BillingOrgLegalEntityError(error.message || 'RPC_FAILED')
  }
  const rec = asRecord(data)
  if (!rec) {
    throw new BillingOrgLegalEntityError('RPC_FAILED')
  }
  if (rec.ok === false) {
    throw new BillingOrgLegalEntityError(String(rec.error || 'RPC_FAILED'))
  }
  return {
    ok: true,
    status: typeof rec.status === 'string' ? rec.status : undefined,
    legalEntityId: typeof rec.legalEntityId === 'string' ? rec.legalEntityId : null,
    listed: rec.listed === true,
  }
}

export async function setOrgListedInProviderDirectory(
  orgId: string,
  listed: boolean,
): Promise<void> {
  const { data, error } = await rpcClient().rpc('set_org_listed_in_provider_directory', {
    p_org_id: orgId,
    p_listed: listed,
  })
  if (error) {
    console.error('[billingOrgLegalEntity] set listed:', error)
    throw new BillingOrgLegalEntityError(error.message || 'RPC_FAILED')
  }
  const rec = asRecord(data)
  if (rec?.ok === false) {
    throw new BillingOrgLegalEntityError(String(rec.error || 'RPC_FAILED'))
  }
}
