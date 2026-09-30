// Generated from web/src by `npm run build`. Do not edit.
"use strict";
(() => {
  // src/policy.ts
  var DEFAULT_CONFIG = { allowSingleReels: true };
  var BLOCKED_PREFIXES = ["/reels/", "/explore/"];
  var SINGLE_REEL_PREFIX = "/reel/";
  function normalizePath(pathname) {
    let path = pathname;
    try {
      path = decodeURIComponent(path);
    } catch {
    }
    path = path.toLowerCase();
    return path.endsWith("/") ? path : `${path}/`;
  }
  function isBlockedPath(pathname, config2) {
    const path = normalizePath(pathname);
    if (BLOCKED_PREFIXES.some((prefix) => path.startsWith(prefix))) return true;
    return !config2.allowSingleReels && path.startsWith(SINGLE_REEL_PREFIX);
  }
  function isInstagramHost(hostname) {
    const host = hostname.toLowerCase();
    return host === "instagram.com" || host.endsWith(".instagram.com");
  }
  function isBlockedURL(url, base, config2) {
    let parsed;
    try {
      parsed = new URL(url, base);
    } catch {
      return false;
    }
    return isInstagramHost(parsed.hostname) && isBlockedPath(parsed.pathname, config2);
  }
  var HIDDEN_LINK_SELECTORS = BLOCKED_PREFIXES.flatMap((prefix) => [
    `a[href^="${prefix}"]`,
    `a[href^="https://www.instagram.com${prefix}"]`
  ]);

  // src/instagram-filter.ts
  var STYLE_ID = "focuslite-filter";
  var HOME = "/";
  function config() {
    return { ...DEFAULT_CONFIG, ...window.__focusLiteConfig };
  }
  function isBlocked(url) {
    return isBlockedURL(url, location.href, config());
  }
  function post(message) {
    const handler = window.webkit?.messageHandlers?.focuslite;
    if (handler) {
      handler.postMessage(message);
    } else {
      console.info("[FocusLite]", message.type, message.url);
    }
  }
  function absolute(url) {
    return new URL(url, location.href).href;
  }
  function redirectHome(blockedUrl) {
    post({ type: "blocked", url: absolute(blockedUrl) });
    location.replace(HOME);
  }
  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = `${HIDDEN_LINK_SELECTORS.join(",\n")} { display: none !important; }`;
    (document.head ?? document.documentElement).appendChild(style);
  }
  function onClick(event) {
    const target = event.target;
    if (!(target instanceof Element)) return;
    const link = target.closest("a[href]");
    if (!(link instanceof HTMLAnchorElement) || !isBlocked(link.href)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    post({ type: "blocked", url: link.href });
  }
  var lastNotifiedUrl = "";
  function notifyNavigation() {
    if (location.href === lastNotifiedUrl) return;
    lastNotifiedUrl = location.href;
    post({ type: "navigation", url: location.href });
  }
  function patchHistory(method) {
    const original = history[method];
    history[method] = function(data, unused, url) {
      if (url != null && isBlocked(url)) {
        redirectHome(url);
        return;
      }
      original.call(this, data, unused, url);
      notifyNavigation();
    };
  }
  function checkCurrentLocation() {
    if (isBlocked(location.href)) {
      redirectHome(location.href);
    } else {
      notifyNavigation();
    }
  }
  var frameScheduled = false;
  function onMutation() {
    if (frameScheduled) return;
    frameScheduled = true;
    requestAnimationFrame(() => {
      frameScheduled = false;
      ensureStyle();
      checkCurrentLocation();
    });
  }
  function install() {
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
})();
