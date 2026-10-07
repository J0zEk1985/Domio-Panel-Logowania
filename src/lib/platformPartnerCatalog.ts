const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export type CatalogOrganization = {
  id: string
  name: string
  owner_id: string | null
}

/** Organizations whose owner is a platform admin. */
export function platformOwnerOrganizations<T extends CatalogOrganization>(
  organizations: T[],
  platformOwnerIds: Iterable<string>,
): T[] {
  const owners = new Set(platformOwnerIds)
  return organizations.filter((org) => org.owner_id != null && owners.has(org.owner_id))
}

/**
 * Partner catalog: rows created in this panel (no source company)
 * plus contractors that belong to a platform-owner organization.
 * Companies synced from tenant organizations stay out of the catalog.
 */
export function platformPartnerVendorFilter(platformOwnerOrgIds: string[]): string {
  const ids = platformOwnerOrgIds.filter((id) => UUID_RE.test(id))
  if (ids.length === 0) return 'company_id.is.null'
  return `company_id.is.null,org_id.in.(${ids.join(',')})`
}
