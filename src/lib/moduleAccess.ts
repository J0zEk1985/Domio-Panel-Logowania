import type { Application } from "../types/database";

const CLEANING_WORKER_ROLES = new Set(["cleaner", "staff"]);

export function isCleaningWorkerOnly(roles: Array<string | null | undefined>): boolean {
  if (roles.length === 0) return false;
  return roles.every((role) => {
    const normalized = (role ?? "").trim().toLowerCase();
    return CLEANING_WORKER_ROLES.has(normalized);
  });
}

function appBlob(app: Application): string {
  return `${app.name} ${app.domain_url ?? ""} ${app.api_url ?? ""}`.toLowerCase();
}

function isCleaningApp(app: Application): boolean {
  return appBlob(app).includes("clean");
}

function isFleetApp(app: Application): boolean {
  const blob = appBlob(app);
  return blob.includes("flot") || blob.includes("fleet");
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
