// Injected into the YouTube WebView at document start.
// Also testable alone: paste the built file into desktop Safari's console, in iPhone responsive mode.
// Blocks Shorts; the rest of YouTube stays available.

import { installFilter } from "./filter.ts";
import { HIDDEN_SELECTORS, isBlockedURL } from "./youtube-policy.ts";

installFilter({ isBlockedURL, redirectTarget: () => null, hiddenSelectors: HIDDEN_SELECTORS });
