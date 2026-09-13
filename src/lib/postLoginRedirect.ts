/** Safe post-login / change-password redirects for DOMIO Hub (no open redirects). */

export const isValidDomioSubdomain = (url: string): boolean => {
  try {
    const urlObj = new URL(url);
    const hostname = urlObj.hostname;
    if (hostname === "localhost" || hostname === "127.0.0.1") return true;
    return hostname === "domio.com.pl" || hostname.endsWith(".domio.com.pl");
  } catch {
    return false;
  }
};

/** Same-origin SPA paths after login (e.g. /admin). Rejects open redirects. */
export const isSafeInternalReturnPath = (path: string): boolean => {
  if (!path.startsWith("/") || path.startsWith("//")) return false;
  const [withoutHash, hash] = path.split("#");
  if (hash != null && hash !== "" && !/^[a-zA-Z0-9_-]+$/.test(hash)) return false;
  const [pathname] = withoutHash.split("?");
  return /^\/[a-zA-Z0-9/_-]*$/.test(pathname) && !pathname.includes("..");
};

export const resolvePostLoginTarget = (returnToParam: string | null): string => {
  if (!returnToParam) return "/dashboard";
  if (isValidDomioSubdomain(returnToParam)) return returnToParam;
  if (isSafeInternalReturnPath(returnToParam)) return returnToParam;
  return "/dashboard";
};

export const buildChangePasswordPath = (returnToParam: string | null): string => {
  const target = resolvePostLoginTarget(returnToParam);
  if (target === "/dashboard") return "/change-password";
  return `/change-password?returnTo=${encodeURIComponent(target)}`;
};

export type FirstLoginProfile = {
  is_first_login?: boolean | null;
  account_type?: string | null;
  fleet_role?: string | null;
};

/**
 * Temporary PIN/password change applies only to simplified workers and fleet
 * drivers created by an admin. Hub/standard owners already set a password.
 */
export function shouldForcePasswordChange(
  profile: FirstLoginProfile | null | undefined
): boolean {
  if (!profile || profile.is_first_login !== true) return false;
  const accountType = (profile.account_type ?? "").trim().toLowerCase();
  const fleetRole = (profile.fleet_role ?? "").trim().toLowerCase();
  if (accountType === "simplified") return true;
  if (fleetRole === "driver") return true;
  return false;
}

export function resolveAuthLanding(
  isFirstLogin: boolean,
  returnToParam: string | null
): { href: string; external: boolean } {
  if (isFirstLogin) {
    return { href: buildChangePasswordPath(returnToParam), external: false };
  }
  const target = resolvePostLoginTarget(returnToParam);
  return { href: target, external: target.startsWith("http") };
}

export function navigateToHref(
  href: string,
  external: boolean,
  navigate: (to: string, options?: { replace?: boolean }) => void
): void {
  if (external) {
    window.location.replace(href);
    return;
  }
  navigate(href, { replace: true });
}
