// Shared by every site policy and the filter engine.

/** Set by native in `window.__focusLiteConfig`, before the filter script runs. */
export interface FilterConfig {
  /** Instagram: allows single reels `/reel/<id>/`, typically received in DMs. */
  allowSingleReels: boolean;
}

export const DEFAULT_CONFIG: FilterConfig = { allowSingleReels: true };

/** Lowercased, percent-decoded, with a trailing slash so `/reels` matches `/reels/`. */
export function normalizePath(pathname: string): string {
  let path = pathname;
  try {
    path = decodeURIComponent(path);
  } catch {
    // Malformed escapes: match on the raw path.
  }
  path = path.toLowerCase();
  return path.endsWith("/") ? path : `${path}/`;
}
