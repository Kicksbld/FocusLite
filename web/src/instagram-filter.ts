// Injected into the Instagram WebView at document start (spec F4).
// Also testable alone: paste the built file into desktop Safari's console, in iPhone responsive mode.
// Blocks Reels and Explore; `/explore/` (Instagram's search button) opens search instead.

import { installFilter } from "./filter.ts";
import { HIDDEN_LINK_SELECTORS, isBlockedURL, redirectTarget } from "./instagram-policy.ts";

installFilter({ isBlockedURL, redirectTarget, hiddenSelectors: HIDDEN_LINK_SELECTORS });
