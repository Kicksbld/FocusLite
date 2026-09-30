// Generated from web/src by `npm run build`. Do not edit.
"use strict";
(() => {
  // src/config.ts
  var DEFAULT_CONFIG = { allowSingleReels: true };
  function normalizePath(pathname) {
    let path = pathname;
    try {
      path = decodeURIComponent(path);
    } catch {
    }
    path = path.toLowerCase();
    return path.endsWith("/") ? path : `${path}/`;
  }

  // src/filter.ts
  var STYLE_ID = "focuslite-filter";
  var HOME = "/";
  var site;
  function config() {
    return { ...DEFAULT_CONFIG, ...window.__focusLiteConfig };
  }
  function isBlocked(url) {
    return site.isBlockedURL(url, location.href, config());
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
  function leave(blockedUrl) {
    const target = site.redirectTarget(blockedUrl, location.href);
    if (target) {
      location.replace(target);
      return;
    }
    post({ type: "blocked", url: absolute(blockedUrl) });
    location.replace(HOME);
  }
  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = site.hiddenSelectors.map((selector) => `${selector} { display: none !important; }`).join("\n");
    (document.head ?? document.documentElement).appendChild(style);
  }
  function onClick(event) {
    const target = event.target;
    if (!(target instanceof Element)) return;
    const link = target.closest("a[href]");
    if (!(link instanceof HTMLAnchorElement) || !isBlocked(link.href)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    const redirect = site.redirectTarget(link.href, location.href);
    if (redirect) {
      location.assign(redirect);
    } else {
      post({ type: "blocked", url: link.href });
    }
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
        leave(url);
        return;
      }
      original.call(this, data, unused, url);
      notifyNavigation();
    };
  }
  function checkCurrentLocation() {
    if (isBlocked(location.href)) {
      leave(location.href);
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
  function installFilter(policy) {
    site = policy;
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

  // src/youtube-policy.ts
  function isBlockedPath(pathname) {
    return normalizePath(pathname).split("/").includes("shorts");
  }
  function isYouTubeHost(hostname) {
    const host = hostname.toLowerCase();
    return host === "youtube.com" || host.endsWith(".youtube.com") || host === "youtu.be";
  }
  function isBlockedURL(url, base) {
    let parsed;
    try {
      parsed = new URL(url, base);
    } catch {
      return false;
    }
    return isYouTubeHost(parsed.hostname) && isBlockedPath(parsed.pathname);
  }
  var hrefs = (path) => [path, `https://m.youtube.com${path}`, `https://www.youtube.com${path}`];
  var HIDDEN_SELECTORS = [
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
    'ytm-grid-shelf-view-model:has(a[href^="/shorts/"])'
  ];

  // src/youtube-filter.ts
  installFilter({ isBlockedURL, redirectTarget: () => null, hiddenSelectors: HIDDEN_SELECTORS });
})();
