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
}
