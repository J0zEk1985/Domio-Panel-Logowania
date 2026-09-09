import type { Application } from "../types/database";
import { getLandingModules, modules, type ModuleData } from "../data/modules";

const CLEANING_WORKER_ROLES = new Set(["cleaner", "staff"]);

const SLUG_HINTS: Record<string, string[]> = {
  cleaning: ["clean"],
  flota: ["flot", "fleet"],
  serwis: ["serwis", "service"],
  administracja: ["administr", "nieruchom", "admin.domio", "adm.domio"],
  home: ["home", "mieszkan"],
};

const HUB_HOSTNAMES = new Set([
  "domio.com.pl",
  "www.domio.com.pl",
  "udomio.com.pl",
  "www.udomio.com.pl",
  "test.udomio.com.pl",
  "test.domio.com.pl",
]);

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

function hostnameFromUrl(url: string | null | undefined): string | null {
  if (!url) return null;
  try {
    return new URL(url).hostname.toLowerCase();
  } catch {
    return null;
  }
}

function isCleaningApp(app: Application): boolean {
  return appBlob(app).includes("clean");
}

function isFleetApp(app: Application): boolean {
  const blob = appBlob(app);
  return blob.includes("flot") || blob.includes("fleet");
}

export function isHubApplication(app: Pick<Application, "name" | "domain_url" | "api_url">): boolean {
  const name = app.name.trim().toLowerCase();
  if (name.includes("auth hub") || name.includes("panel logowania")) return true;
  const host = hostnameFromUrl(app.domain_url) ?? hostnameFromUrl(app.api_url);
  return host != null && HUB_HOSTNAMES.has(host);
}

export function applicationMatchesModuleSlug(
  app: Pick<Application, "name" | "domain_url" | "api_url">,
  slug: string,
): boolean {
  const blob = appBlob(app);
  return (SLUG_HINTS[slug] ?? []).some((hint) => blob.includes(hint));
}

export function catalogModuleForApplication(
  app: Pick<Application, "name" | "domain_url" | "api_url">,
): ModuleData | undefined {
  const listed = getLandingModules().find((mod) => applicationMatchesModuleSlug(app, mod.slug));
  if (listed) return listed;
  return modules.find((mod) => applicationMatchesModuleSlug(app, mod.slug));
}

export function sortApplicationsByCatalog(apps: Application[]): Application[] {
  const order = getLandingModules().map((mod) => mod.slug);
  return [...apps].sort((a, b) => {
    const ia = order.findIndex((slug) => applicationMatchesModuleSlug(a, slug));
    const ib = order.findIndex((slug) => applicationMatchesModuleSlug(b, slug));
    const ra = ia === -1 ? order.length : ia;
    const rb = ib === -1 ? order.length : ib;
    if (ra !== rb) return ra - rb;
    return a.name.localeCompare(b.name, "pl");
  });
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
  const productApps = apps.filter((app) => !isHubApplication(app));
  const hasFleet = opts.fleetRole === "admin" || opts.fleetRole === "driver";
  if (!isCleaningWorkerOnly(opts.membershipRoles)) {
    return productApps;
  }

  return productApps.filter((app) => {
    if (isCleaningApp(app)) return true;
    if (hasFleet && isFleetApp(app)) return true;
    return false;
  });
}
