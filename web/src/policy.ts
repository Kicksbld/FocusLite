// URL rules shared by every interception point of the filter script.
// Mirrors the native URLPolicy (spec F4). Paths only: never CSS classes or UI text.

export interface FilterConfig {
  /** Allows single reels `/reel/<id>/`, typically received in DMs. */
  allowSingleReels: boolean;
}

export const DEFAULT_CONFIG: FilterConfig = { allowSingleReels: true };

/**
 * Always blocked. `/reels/` also covers `/reels/<id>/`, which opens a reel inside
 * the scrollable Reels feed. `/explore/` also covers search, tags and locations.
 */
const BLOCKED_PREFIXES = ["/reels/", "/explore/"];

const SINGLE_REEL_PREFIX = "/reel/";

/** Lowercased, percent-decoded, with a trailing slash so `/reels` matches `/reels/`. */
function normalizePath(pathname: string): string {
  let path = pathname;
  try {
    path = decodeURIComponent(path);
  } catch {
    // Malformed escapes: match on the raw path.
  }
  path = path.toLowerCase();
  return path.endsWith("/") ? path : `${path}/`;
}

export function isBlockedPath(pathname: string, config: FilterConfig): boolean {
  const path = normalizePath(pathname);
  if (BLOCKED_PREFIXES.some((prefix) => path.startsWith(prefix))) return true;
  return !config.allowSingleReels && path.startsWith(SINGLE_REEL_PREFIX);
}

export function isInstagramHost(hostname: string): boolean {
  const host = hostname.toLowerCase();
  return host === "instagram.com" || host.endsWith(".instagram.com");
}

/** Resolves `url` against `base` and applies the rules. External URLs are never blocked here. */
export function isBlockedURL(url: string | URL, base: string, config: FilterConfig): boolean {
  let parsed: URL;
  try {
    parsed = new URL(url, base);
  } catch {
    return false;
  }
  return isInstagramHost(parsed.hostname) && isBlockedPath(parsed.pathname, config);
}

/** Links to hide. Covers relative and absolute hrefs. */
export const HIDDEN_LINK_SELECTORS = BLOCKED_PREFIXES.flatMap((prefix) => [
  `a[href^="${prefix}"]`,
  `a[href^="https://www.instagram.com${prefix}"]`,
]);
