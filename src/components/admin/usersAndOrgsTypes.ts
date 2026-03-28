export type UsersOrgsSubTab = 'orgs' | 'users'

export type SortDirection = 'asc' | 'desc'

export type OrgSortKey = 'name' | 'nip' | 'city' | 'created_at'
export type UserSortKey = 'full_name' | 'email' | 'platform_role' | 'last_login_at'

export type OrgSortConfig = { key: OrgSortKey; direction: SortDirection }
export type UserSortConfig = { key: UserSortKey; direction: SortDirection }

export type OrganizationListRow = {
  id: string
  name: string
  nip: string | null
  city: string | null
  created_at: string
}

export type ProfileListRow = {
  id: string
  first_name: string | null
  last_name: string | null
  full_name: string | null
  email: string | null
  platform_role: string | null
  last_login_at: string | null
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

/** Supabase may return nested FK as object or single-element array depending on schema cache. */
export type OrgSubscriptionRow = {
  id: string
  org_id: string
  app_id: string
  status: string
  created_at: string | null
  applications: { name: string } | { name: string }[] | null
}

export type MembershipWithProfile = {
  id: string
  role: string
  profiles: {
    first_name: string | null
    last_name: string | null
    full_name: string | null
    email: string | null
  } | null
}

export type MembershipWithOrg = {
  id: string
  role: string
  organizations: { name: string } | { name: string }[] | null
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
