export interface Application {
  id: string
  name: string
  domain_url: string
  api_url: string | null
  is_free: boolean
  is_active: boolean
  created_at: string
}

export interface UserAppAccess {
  user_id: string
  app_id: string
  app_name: string
  app_domain_url: string
  app_api_url: string | null
  org_id: string
  org_name: string
  subscription_status: string
}

export interface CleaningStaff {
  id: string
  org_id: string | null
  full_name: string
  phone: string | null
  internal_id: string | null
  pin: string | null
  is_active: boolean
  created_at: string
}

export interface Profile {
  id: string
  full_name: string | null
  accepted_terms_at: string
  ip_address: string | null
  marketing_consent: boolean
  updated_at: string
  terms_version: string
  privacy_version?: string | null
  marketing_version?: string | null
}

/** Cache on profiles is not legal proof. Source of truth: UserConsent. */
export type LegalDocType = 'terms' | 'privacy' | 'marketing'
export type LegalConsentSource = 'signup_email' | 'signup_oauth' | 'reacceptance'
export type LegalWelcomeDispatchStatus = 'pending' | 'processing' | 'sent' | 'failed'

export interface LegalDocument {
  id: string
  document_type: LegalDocType
  version: string
  content: string
  content_hash: string
  active_from: string
  active_until: string | null
  is_active: boolean
  is_required: boolean
  published_at: string
  created_by: string | null
}

export interface UserConsentBatch {
  id: string
  user_id: string
  accepted_at: string
  source: LegalConsentSource
  email: string
  ip_address: string | null
  user_agent: string | null
  pdf_sha256: string | null
  pdf_storage_path: string | null
  created_at: string
}

export interface UserConsent {
  id: string
  batch_id: string
  user_id: string
  document_id: string
  document_type: LegalDocType
  document_version: string
  accepted_at: string
  ip_address: string | null
  user_agent: string | null
  acceptance_hash: string
  created_at: string
}

export interface LegalWelcomeDispatch {
  id: string
  batch_id: string
  status: LegalWelcomeDispatchStatus
  attempt_count: number
  last_error: string | null
  provider: string
  provider_message_id: string | null
  sent_at: string | null
  next_attempt_at: string
  created_at: string
}

/** RPC contract for the consent wall (implemented in Layer 2). */
export interface PendingRequiredLegalDocument {
  id: string
  document_type: LegalDocType
  version: string
  active_from: string
}

export interface VerifyUserConsentResult {
  ok: boolean
  consent_id?: string
  user_id?: string
  document_id?: string
  document_version?: string
  accepted_at?: string
  hash_matches?: boolean
  pdf_sha256_present?: boolean
  reason?: string | null
}
