import type { Application } from "../types/database";

const CLEANING_WORKER_ROLES = new Set(["cleaner", "staff"]);

const SLUG_HINTS: Record<string, string[]> = {
  cleaning: ["clean"],
  flota: ["flot", "fleet"],
  serwis: ["serwis", "service"],
  administracja: ["administr", "nieruchom"],
  home: ["home", "mieszkan"],
};

export function isCleaningWorkerOnly(roles: Array<string | null | undefined>): boolean {
  if (roles.length === 0) return false;
  return roles.every((role) => {
    const normalized = (role ?? "").trim().toLowerCase();
    return CLEANING_WORKER_ROLES.has(normalized);
  });
}

function appBlob(app: Pick<Application, "name" | "domain_url" | "api_url">): string {
  return `${app.name} ${app.domain_url ?? ""} ${app.api_url ?? ""}`.toLowerCase();
}

function isCleaningApp(app: Application): boolean {
  return appBlob(app).includes("clean");
}

function isFleetApp(app: Application): boolean {
  const blob = appBlob(app);
  return blob.includes("flot") || blob.includes("fleet");
}

export function applicationMatchesModuleSlug(
  app: Pick<Application, "name" | "domain_url" | "api_url">,
  slug: string,
): boolean {
  const blob = appBlob(app);
  return (SLUG_HINTS[slug] ?? []).some((hint) => blob.includes(hint));
}

export function isSubscriptionCurrent(status: string | null | undefined, expiresAt: string | null | undefined): boolean {
  if ((status ?? "").trim().toLowerCase() !== "active") return false;
  if (!expiresAt) return true;
  const expires = new Date(expiresAt);
  if (Number.isNaN(expires.getTime())) return true;
  return expires.getTime() > Date.now();
}

/**
 * Free apps are always listed. Paid apps require an active, unexpired org subscription.
 * Platform admins see every active application.
 */
export function filterAppsByOrgAccess(
  apps: Application[],
  opts: {
    isPlatformAdmin: boolean;
    subscribedAppIds: Set<string>;
  },
): Application[] {
  if (opts.isPlatformAdmin) return apps;
  return apps.filter((app) => app.is_free || opts.subscribedAppIds.has(app.id));
}

/**
 * Cleaning-only workers (simplified cleaner/staff) must not see Serwis/other modules
 * just because SSO session is shared with the same organisation.
 */
export function filterHubApplications(
  apps: Application[],
  opts: { membershipRoles: Array<string | null | undefined>; fleetRole: string | null }
): Application[] {
  const hasFleet = opts.fleetRole === "admin" || opts.fleetRole === "driver";
  if (!isCleaningWorkerOnly(opts.membershipRoles)) {
    return apps;
  }

  return apps.filter((app) => {
    if (isCleaningApp(app)) return true;
    if (hasFleet && isFleetApp(app)) return true;
    return false;
  });
}
