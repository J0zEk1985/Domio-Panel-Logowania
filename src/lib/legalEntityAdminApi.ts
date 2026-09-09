import { supabase } from './supabase'
import { legalEntityErrorMessage, type LegalEntityKind } from './legalEntityMessages'

export type LegalEntityVerificationReason = 'gus_unavailable' | 'gus_not_configured'

export type PlatformVerificationAlert = {
  legalEntityId: string
  orgId: string | null
  orgName: string | null
  kind: LegalEntityKind
  nip: string
  shortName: string
  createdAt: string
  reason: LegalEntityVerificationReason | null
  overlayKind: 'community' | 'company'
  overlayId: string | null
}

export class LegalEntityAdminApiError extends Error {
  readonly code: string

  constructor(code: string) {
    super(legalEntityErrorMessage(code))
    this.name = 'LegalEntityAdminApiError'
    this.code = code
  }
}

type RpcClient = {
  rpc: (
    fn: string,
    args?: Record<string, unknown>,
  ) => Promise<{ data: unknown; error: { message: string } | null }>
}

function rpcClient(): RpcClient {
  return supabase as unknown as RpcClient
}

function asAlertList(raw: unknown): PlatformVerificationAlert[] {
  let value: unknown = raw
  if (typeof value === 'string') {
    try {
      value = JSON.parse(value)
    } catch {
      return []
    }
  }
  if (!Array.isArray(value)) return []
  return value as PlatformVerificationAlert[]
}

export async function listPlatformVerificationAlerts(): Promise<PlatformVerificationAlert[]> {
  const { data, error } = await rpcClient().rpc('list_platform_verification_alerts')
  if (error) {
    console.error('[legalEntityAdminApi] list_platform_verification_alerts:', error)
    throw new LegalEntityAdminApiError(error.message || 'RPC_FAILED')
  }
  return asAlertList(data)
}

export async function countPlatformVerificationAlerts(): Promise<number> {
  const { data, error } = await rpcClient().rpc('count_platform_verification_alerts')
  if (error) {
    console.error('[legalEntityAdminApi] count_platform_verification_alerts:', error)
    throw new LegalEntityAdminApiError(error.message || 'RPC_FAILED')
  }
  return typeof data === 'number' ? data : 0
}

export async function resolveLegalEntityVerification(legalEntityId: string): Promise<void> {
  const { error } = await rpcClient().rpc('resolve_legal_entity_verification', {
    p_legal_entity_id: legalEntityId,
  })
  if (error) {
    console.error('[legalEntityAdminApi] resolve_legal_entity_verification:', error)
    throw new LegalEntityAdminApiError(error.message || 'RPC_FAILED')
  }
}

export async function retryLegalEntityGus(legalEntityId: string): Promise<void> {
  const { data, error } = await supabase.functions.invoke('lookup-legal-entity', {
    body: { action: 'retryGus', legalEntityId },
  })

  let payload: Record<string, unknown> | null = null
  if (data && typeof data === 'object' && !Array.isArray(data)) {
    payload = data as Record<string, unknown>
  }

  if (error) {
    const context = (error as { context?: Response }).context
    if (context && typeof context.json === 'function') {
      try {
        const parsed = await context.json()
        if (parsed && typeof parsed === 'object') payload = parsed as Record<string, unknown>
      } catch {
        console.error('[legalEntityAdminApi] parse retryGus error body failed')
      }
    }
    const code =
      (typeof payload?.error === 'string' && payload.error) ||
      (typeof payload?.status === 'string' && payload.status) ||
      'RPC_FAILED'
    console.error('[legalEntityAdminApi] retryGus:', code, error)
    throw new LegalEntityAdminApiError(code)
  }

  if (payload && typeof payload.error === 'string') {
    throw new LegalEntityAdminApiError(payload.error)
  }
}
