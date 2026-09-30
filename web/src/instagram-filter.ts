// Injected into the Instagram WebView at document start (spec F4).
// Also testable alone: paste the built file into desktop Safari's console, in iPhone responsive mode.
//
// Blocks Reels and Explore at four points, since instagram.com is a React SPA that
// changes pages without full loads the native side could see:
//   1. link clicks (capture phase, before the router reacts): cancelled, the page stays;
//   2. history.pushState / replaceState: skipped, then redirect to "/";
//   3. popstate and the initial URL: redirect to "/";
//   4. CSS hiding the Reels / Explore links, kept in place by a MutationObserver.
// Redirected paths (`/explore/`, the target of Instagram's search button) open their
// target instead, with a full page load, at the same four points.
//
// Messages posted to window.webkit.messageHandlers.focuslite:
//   { type: "navigation", url }  the URL changed to an allowed page
//   { type: "blocked", url }     a navigation to `url` was blocked (native shows a toast)

import { DEFAULT_CONFIG, HIDDEN_LINK_SELECTORS, type FilterConfig, isBlockedURL, redirectTarget } from "./policy.ts";

type FilterMessage = { type: "navigation" | "blocked"; url: string };

declare global {
  interface Window {
    /** Set by native in a script injected before this one. Read on every check, so it can change. */
    __focusLiteConfig?: Partial<FilterConfig>;
    __focusLiteFilterInstalled?: boolean;
    webkit?: { messageHandlers?: { focuslite?: { postMessage(message: FilterMessage): void } } };
  }
}

const STYLE_ID = "focuslite-filter";
const HOME = "/";

function config(): FilterConfig {
  return { ...DEFAULT_CONFIG, ...window.__focusLiteConfig };
}

function isBlocked(url: string | URL): boolean {
  return isBlockedURL(url, location.href, config());
}

function post(message: FilterMessage): void {
  const handler = window.webkit?.messageHandlers?.focuslite;
  if (handler) {
    handler.postMessage(message);
  } else {
    console.info("[FocusLite]", message.type, message.url);
  }
}

function absolute(url: string | URL): string {
  return new URL(url, location.href).href;
}

/** Leaves a blocked URL: to its redirect target if it has one, else home with a "blocked" message. */
function leave(blockedUrl: string | URL): void {
  const target = redirectTarget(blockedUrl, location.href);
  if (target) {
    location.replace(target);
    return;
  }
  post({ type: "blocked", url: absolute(blockedUrl) });
  location.replace(HOME);
}

// 4. CSS hiding

function ensureStyle(): void {
  if (document.getElementById(STYLE_ID)) return;
  const style = document.createElement("style");
  style.id = STYLE_ID;
  style.textContent = `${HIDDEN_LINK_SELECTORS.join(",\n")} { display: none !important; }`;
  // At document start <head> may not exist yet.
  (document.head ?? document.documentElement).appendChild(style);
}

// 1. Link clicks

function onClick(event: MouseEvent): void {
  const target = event.target;
  if (!(target instanceof Element)) return;
  const link = target.closest("a[href]");
  if (!(link instanceof HTMLAnchorElement) || !isBlocked(link.href)) return;
  event.preventDefault();
  event.stopImmediatePropagation();
  const redirect = redirectTarget(link.href, location.href);
  if (redirect) {
    location.assign(redirect);
  } else {
    post({ type: "blocked", url: link.href });
  }
}

// 2. History API

let lastNotifiedUrl = "";

function notifyNavigation(): void {
  if (location.href === lastNotifiedUrl) return;
  lastNotifiedUrl = location.href;
  post({ type: "navigation", url: location.href });
}

function patchHistory(method: "pushState" | "replaceState"): void {
  const original = history[method];
  history[method] = function (this: History, data: unknown, unused: string, url?: string | URL | null) {
    if (url != null && isBlocked(url)) {
      leave(url);
      return;
    }
    original.call(this, data, unused, url);
    notifyNavigation();
  };
}

// 3. popstate and current URL

function checkCurrentLocation(): void {
  if (isBlocked(location.href)) {
    leave(location.href);
  } else {
    notifyNavigation();
  }
}

// DOM changes: one check per animation frame at most.

let frameScheduled = false;

function onMutation(): void {
  if (frameScheduled) return;
  frameScheduled = true;
  requestAnimationFrame(() => {
    frameScheduled = false;
    ensureStyle();
    checkCurrentLocation();
  });
}

function install(): void {
  // Idempotent: a second injection only re-checks the page (the config may have changed).
  if (window.__focusLiteFilterInstalled) {
    checkCurrentLocation();
    return;
  }
  window.__focusLiteFilterInstalled = true;

  ensureStyle();
  document.addEventListener("click", onClick, true);
  patchHistory("pushState");
  patchHistory("replaceState");
  window.addEventListener("popstate", checkCurrentLocation);
  new MutationObserver(onMutation).observe(document.documentElement, { childList: true, subtree: true });
  checkCurrentLocation();
}

install();
