import assert from "node:assert/strict";
import { test } from "node:test";
import { isBlockedPath, isBlockedURL } from "../src/youtube-policy.ts";

const base = "https://m.youtube.com/";

test("blocks Shorts and channel Shorts tabs", () => {
  for (const path of ["/shorts/BwGS3SEdVVQ", "/shorts/", "/shorts", "/SHORTS/abc", "/@MrBeast/shorts", "/channel/UC123/shorts/", "/c/name/shorts"]) {
    assert.equal(isBlockedPath(path), true, path);
  }
});

test("allows everything else, including handles that contain shorts", () => {
  for (const path of ["/", "/watch", "/results", "/@MrBeast", "/@MrBeast/videos", "/@rainbow.noob.shorts", "/@ShortsdejaQue", "/feed/subscriptions", "/playlist"]) {
    assert.equal(isBlockedPath(path), false, path);
  }
});

test("resolves relative and absolute URLs, ignores other hosts", () => {
  assert.equal(isBlockedURL("/shorts/abc", base), true);
  assert.equal(isBlockedURL("https://www.youtube.com/shorts/abc?feature=share", base), true);
  assert.equal(isBlockedURL("https://youtube.com/shorts/abc", base), true);
  assert.equal(isBlockedURL("/watch?v=abc&list=shorts", base), false);
  assert.equal(isBlockedURL("https://youtu.be/abc", base), false);
  assert.equal(isBlockedURL("https://example.com/shorts/abc", base), false);
  assert.equal(isBlockedURL("https://notyoutube.com/shorts/abc", base), false);
});
