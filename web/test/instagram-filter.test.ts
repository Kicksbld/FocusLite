// Runs the built script (what the app ships) in a simulated DOM.
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { JSDOM, VirtualConsole } from "jsdom";

const script = readFileSync(new URL("../../FocusLite/Resources/instagram-filter.js", import.meta.url), "utf8");

type Message = { type: string; url: string };

function load(path = "/", config?: object) {
  // Messages are copied out of the jsdom realm so deepEqual compares plain objects.
  // jsdom does not implement navigation: location.replace only logs, which we silence.
  const dom = new JSDOM(
    `<body><nav><a href="/">Home</a><a href="/reels/">R</a><a href="/explore/">E</a><a href="/explore/search/">S</a>` +
      `<a href="/reel/C0abc/">One reel</a><a href="/direct/inbox/">DM</a></nav></body>`,
    { url: `https://www.instagram.com${path}`, runScripts: "outside-only", pretendToBeVisual: true, virtualConsole: new VirtualConsole() },
  );
  const window = dom.window as unknown as Window & typeof globalThis & { eval(code: string): void };
  const messages: Message[] = [];
  Object.assign(window, {
    webkit: { messageHandlers: { focuslite: { postMessage: (m: Message) => messages.push({ ...m }) } } },
    __focusLiteConfig: config,
  });
  window.eval(script);
  return { window, document: window.document, messages };
}

function click(document: Document, href: string) {
  const link = document.querySelector(`a[href="${href}"]`)!;
  const event = new document.defaultView!.MouseEvent("click", { bubbles: true, cancelable: true });
  link.dispatchEvent(event);
  return event;
}

test("hides Reels and Explore links only", () => {
  const { window, document } = load();
  const display = (href: string) => window.getComputedStyle(document.querySelector(`a[href="${href}"]`)!).display;
  assert.equal(display("/reels/"), "none");
  assert.equal(display("/explore/"), "none");
  assert.notEqual(display("/direct/inbox/"), "none");
  assert.notEqual(display("/explore/search/"), "none");
  assert.notEqual(display("/reel/C0abc/"), "none");
});

test("cancels clicks on blocked links before the page sees them", () => {
  const { document, messages } = load();
  let routerSawClick = false;
  document.addEventListener("click", () => (routerSawClick = true));
  assert.equal(click(document, "/reels/").defaultPrevented, true);
  assert.equal(routerSawClick, false);
  assert.deepEqual(messages.at(-1), { type: "blocked", url: "https://www.instagram.com/reels/" });
  assert.equal(click(document, "/direct/inbox/").defaultPrevented, false);
});

test("reports allowed history navigation and refuses blocked ones", () => {
  const { window, messages } = load();
  window.history.pushState({}, "", "/direct/inbox/");
  assert.equal(window.location.pathname, "/direct/inbox/");
  assert.deepEqual(messages.at(-1), { type: "navigation", url: "https://www.instagram.com/direct/inbox/" });

  window.history.pushState({}, "", "/reels/C0abc/");
  window.history.replaceState({}, "", "/explore/");
  assert.equal(window.location.pathname, "/direct/inbox/");
  assert.deepEqual(messages.slice(-2).map((m) => m.type), ["blocked", "blocked"]);
});

test("blocks a blocked initial URL", () => {
  const { messages } = load("/reels/");
  assert.deepEqual(messages, [{ type: "blocked", url: "https://www.instagram.com/reels/" }]);
});

test("single reels follow the native config", () => {
  assert.equal(click(load().document, "/reel/C0abc/").defaultPrevented, false);
  assert.equal(click(load("/", { allowSingleReels: false }).document, "/reel/C0abc/").defaultPrevented, true);
});

test("is idempotent", () => {
  const { window, document, messages } = load();
  window.eval(script);
  assert.equal(document.querySelectorAll("#focuslite-filter").length, 1);
  const before = messages.length;
  window.history.pushState({}, "", "/p/C0abc/");
  assert.equal(messages.length, before + 1);
});
