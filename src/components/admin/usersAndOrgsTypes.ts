export type UsersOrgsSubTab = 'orgs' | 'users'

export type SortDirection = 'asc' | 'desc'

/** List view columns aligned with public schema (Supabase Snippet Public Schema Metadata Snapshot (9).csv). */
export type OrgSortKey = 'name' | 'nip' | 'city' | 'created_at'
export type UserSortKey = 'full_name' | 'email' | 'platform_role' | 'updated_at'

export type OrgSortConfig = { key: OrgSortKey; direction: SortDirection }
export type UserSortConfig = { key: UserSortKey; direction: SortDirection }

export type OrganizationListRow = {
  id: string
  name: string
  nip: string | null
  city: string | null
  created_at: string | null
}

export type ProfileListRow = {
  id: string
  first_name: string | null
  last_name: string | null
  full_name: string | null
  email: string | null
  platform_role: string | null
  updated_at: string | null
}

export type OrganizationDetailRow = {
  id: string
  name: string
  nip: string | null
  address: string | null
  city: string | null
  postal_code: string | null
  created_at: string
}

/** applications dołączane w kodzie po osobnym zapytaniu do tabeli applications */
export type OrgSubscriptionRow = {
  id: string
  org_id: string
  app_id: string
  status: string
  created_at: string | null
  applications: { name: string } | null
}

export type MembershipWithProfile = {
  id: string
  user_id: string
  role: string
  profiles: {
    first_name: string | null
    last_name: string | null
    full_name?: string | null
    email: string | null
  } | null
}

export type MembershipWithOrg = {
  id: string
  org_id: string
  role: string
  /** Uzupełniane po osobnym zapytaniu do organizations */
  organizations: { name: string } | null
}

export type ProfileDetailRow = {
  id: string
  first_name: string | null
  last_name: string | null
  full_name: string | null
  email: string | null
  phone: string | null
  platform_role: string | null
  accepted_terms_at: string | null
  terms_version: string | null
  marketing_consent: boolean | null
  created_at: string | null
  last_login_at: string | null
}

export type TaskExecutionLogRow = {
  id: string
  action_type: string
  notes: string | null
  created_at: string | null
}
