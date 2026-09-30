// YouTube URL rules, shared by every interception point of the filter script.
// Mirrors the native URLPolicy. Paths, `href`s and YouTube's custom element names only:
// never CSS classes or UI text.

import { normalizePath } from "./config.ts";

/**
 * A `shorts` path segment: `/shorts/<id>` (the Shorts player, which swipes to the next Short)
 * and a channel's Shorts tab (`/@name/shorts`, `/channel/<id>/shorts`). An exact segment,
 * so a handle such as `/@name.shorts` stays allowed.
 */
export function isBlockedPath(pathname: string): boolean {
  return normalizePath(pathname).split("/").includes("shorts");
}

export function isYouTubeHost(hostname: string): boolean {
  const host = hostname.toLowerCase();
  return host === "youtube.com" || host.endsWith(".youtube.com") || host === "youtu.be";
}

/** Resolves `url` against `base` and applies the rules. External URLs are never blocked here. */
export function isBlockedURL(url: string | URL, base: string): boolean {
  let parsed: URL;
  try {
    parsed = new URL(url, base);
  } catch {
    return false;
  }
  return isYouTubeHost(parsed.hostname) && isBlockedPath(parsed.pathname);
}

const hrefs = (path: string) => [path, `https://m.youtube.com${path}`, `https://www.youtube.com${path}`];

export const HIDDEN_SELECTORS = [
  // Shorts, and a channel's Shorts tab.
  ...hrefs("/shorts/").map((href) => `a[href^="${href}"]`),
  'a[href$="/shorts"]',
  'a[href$="/shorts/"]',
  // Containers of Shorts, so no empty shelf remains. Element names follow YouTube's renderer
  // names (`pivotBarRenderer` is `<ytm-pivot-bar-renderer>`), but these ones are unverified on
  // the live site. Harmless if they match nothing: the links above are hidden anyway.
  "ytm-shorts-lockup-view-model",
  "ytm-shorts-lockup-view-model-v2",
  "ytm-reel-shelf-renderer",
  'grid-shelf-view-model:has(a[href^="/shorts/"])',
  'ytm-grid-shelf-view-model:has(a[href^="/shorts/"])',
];
