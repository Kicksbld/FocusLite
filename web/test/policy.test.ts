import assert from "node:assert/strict";
import { test } from "node:test";
import { DEFAULT_CONFIG, isBlockedPath, isBlockedURL } from "../src/policy.ts";

const base = "https://www.instagram.com/";
const noSingleReels = { allowSingleReels: false };

test("blocks the Reels feed and its sub-paths", () => {
  for (const path of ["/reels/", "/reels", "/reels/C0abc123/", "/reels/audio/123/", "/REELS/", "/%72eels/"]) {
    assert.equal(isBlockedPath(path, DEFAULT_CONFIG), true, path);
  }
});

test("blocks Explore and its sub-paths", () => {
  for (const path of ["/explore/", "/explore", "/explore/tags/cats/", "/explore/locations/1/", "/explore/people/", "/explore/searching/"]) {
    assert.equal(isBlockedPath(path, DEFAULT_CONFIG), true, path);
  }
});

test("allows search under Explore", () => {
  for (const path of ["/explore/search/", "/explore/search", "/explore/search/keyword/", "/explore/search/results/"]) {
    assert.equal(isBlockedPath(path, DEFAULT_CONFIG), false, path);
  }
});

test("single reels follow allowSingleReels", () => {
  for (const path of ["/reel/C0abc123/", "/reel/C0abc123/some-slug/"]) {
    assert.equal(isBlockedPath(path, DEFAULT_CONFIG), false, path);
    assert.equal(isBlockedPath(path, noSingleReels), true, path);
  }
});

test("allows everything else", () => {
  for (const path of ["/", "/direct/inbox/", "/direct/t/123/", "/stories/someone/1/", "/p/C0abc/", "/someone/", "/accounts/edit/", "/reelsfan/", "/explorer_account/"]) {
    assert.equal(isBlockedPath(path, noSingleReels), false, path);
  }
});

test("resolves relative and absolute URLs, ignores other hosts", () => {
  assert.equal(isBlockedURL("/reels/", base, DEFAULT_CONFIG), true);
  assert.equal(isBlockedURL("https://instagram.com/explore/", base, DEFAULT_CONFIG), true);
  assert.equal(isBlockedURL("https://www.instagram.com/reels/?x=1#y", base, DEFAULT_CONFIG), true);
  assert.equal(isBlockedURL("https://example.com/reels/", base, DEFAULT_CONFIG), false);
  assert.equal(isBlockedURL("https://notinstagram.com/reels/", base, DEFAULT_CONFIG), false);
  assert.equal(isBlockedURL("/direct/inbox/", base, DEFAULT_CONFIG), false);
});
