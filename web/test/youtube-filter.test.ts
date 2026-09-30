// Runs the built script (what the app ships) in a simulated DOM.
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { JSDOM, VirtualConsole } from "jsdom";

const script = readFileSync(new URL("../../FocusLite/Resources/youtube-filter.js", import.meta.url), "utf8");

type Message = { type: string; url: string };

function load(path = "/") {
  const dom = new JSDOM(
    `<body><a href="/watch?v=abc">Video</a><a href="/shorts/BwGS3SEdVVQ">Short</a>` +
      `<a href="/@MrBeast">Channel</a><a href="/@MrBeast/shorts">Channel Shorts</a><a href="/@name.shorts">Handle</a>` +
      `<ytm-reel-shelf-renderer id="shelf"></ytm-reel-shelf-renderer></body>`,
    { url: `https://m.youtube.com${path}`, runScripts: "outside-only", pretendToBeVisual: true, virtualConsole: new VirtualConsole() },
  );
  const window = dom.window as unknown as Window & typeof globalThis & { eval(code: string): void };
  const messages: Message[] = [];
  Object.assign(window, {
    webkit: { messageHandlers: { focuslite: { postMessage: (m: Message) => messages.push({ ...m }) } } },
  });
  window.eval(script);
  return { window, document: window.document, messages };
}

test("hides Shorts links and shelves, keeps videos and channels", () => {
  const { window, document } = load();
  const display = (selector: string) => window.getComputedStyle(document.querySelector(selector)!).display;
  assert.equal(display('a[href="/shorts/BwGS3SEdVVQ"]'), "none");
  assert.equal(display('a[href="/@MrBeast/shorts"]'), "none");
  assert.equal(display("#shelf"), "none");
  assert.notEqual(display('a[href="/watch?v=abc"]'), "none");
  assert.notEqual(display('a[href="/@MrBeast"]'), "none");
  assert.notEqual(display('a[href="/@name.shorts"]'), "none");
});

test("cancels clicks on Shorts and refuses history navigation to them", () => {
  const { window, document, messages } = load();
  const event = new window.MouseEvent("click", { bubbles: true, cancelable: true });
  document.querySelector('a[href="/shorts/BwGS3SEdVVQ"]')!.dispatchEvent(event);
  assert.equal(event.defaultPrevented, true);
  assert.deepEqual(messages.at(-1), { type: "blocked", url: "https://m.youtube.com/shorts/BwGS3SEdVVQ" });

  window.history.pushState({}, "", "/watch?v=abc");
  assert.deepEqual(messages.at(-1), { type: "navigation", url: "https://m.youtube.com/watch?v=abc" });
  window.history.pushState({}, "", "/shorts/xyz");
  assert.equal(window.location.pathname, "/watch");
  assert.equal(messages.at(-1)?.type, "blocked");
});

test("blocks a Shorts initial URL", () => {
  assert.deepEqual(load("/shorts/abc").messages, [{ type: "blocked", url: "https://m.youtube.com/shorts/abc" }]);
});
