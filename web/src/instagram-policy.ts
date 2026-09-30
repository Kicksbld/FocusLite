// Instagram URL rules, shared by every interception point of the filter script.
// Mirrors the native URLPolicy (spec F4). Paths only: never CSS classes or UI text.

import { type FilterConfig, normalizePath } from "./config.ts";

/**
 * Always blocked. `/reels/` also covers `/reels/<id>/`, which opens a reel inside
 * the scrollable Reels feed. `/explore/` also covers tags, locations and people.
 */
const BLOCKED_PREFIXES = ["/reels/", "/explore/"];

/** Exceptions to `BLOCKED_PREFIXES`: account search lives under Explore on mobile. */
const ALLOWED_PREFIXES = ["/explore/search/"];

const SINGLE_REEL_PREFIX = "/reel/";

/**
 * Blocked paths that open another page instead of being blocked. Instagram's own
 * search button links to `/explore/`: it opens search rather than the Explore grid.
 */
const REDIRECTS = new Map([["/explore/", "/explore/search/"]]);


export function isBlockedPath(pathname: string, config: FilterConfig): boolean {
  const path = normalizePath(pathname);
  if (ALLOWED_PREFIXES.some((prefix) => path.startsWith(prefix))) return false;
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

/** Path to open instead of `url`, if `url` is one of the `REDIRECTS`. */
export function redirectTarget(url: string | URL, base: string): string | null {
  let parsed: URL;
  try {
    parsed = new URL(url, base);
  } catch {
    return null;
  }
  if (!isInstagramHost(parsed.hostname)) return null;
  return REDIRECTS.get(normalizePath(parsed.pathname)) ?? null;
}

const hrefPrefixes = (prefix: string) => [prefix, `https://www.instagram.com${prefix}`];

/** Links to hide: blocked prefixes minus the allowed ones and the redirected ones. */
const allowedLinks = [
  ...ALLOWED_PREFIXES.flatMap(hrefPrefixes).map((href) => `:not([href^="${href}"])`),
  ...[...REDIRECTS.keys()].flatMap(hrefPrefixes).map((href) => `:not([href="${href}"])`),
].join("");

export const HIDDEN_LINK_SELECTORS = BLOCKED_PREFIXES.flatMap(hrefPrefixes).map(
  (href) => `a[href^="${href}"]${allowedLinks}`,
);
