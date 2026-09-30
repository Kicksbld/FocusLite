# DESIGN.md — FocusLite design system

This file tells an AI (or a human) how FocusLite must look and feel. Read it before writing or changing any SwiftUI view, shield, or notification. `CLAUDE.md` covers architecture; `cahier-des-charges.md` covers scope. This file covers appearance only.

## 1. Intent in one paragraph

FocusLite should feel like an app Apple could have shipped: calm, native, and quiet. It is built from standard SwiftUI components that pick up **Liquid Glass** automatically, on a graphite base taken from the app icon, with **one orange accent** used rarely and on purpose. The app exists to take attention *away* from a screen, so the UI must never compete for it: no decoration, no gradients on content, no badges or streaks, no bright color floods. When unsure, do what the iOS system apps (Settings, Clock, Screen Time) do.

## 2. The icon is the source of truth

The icon (`FocusLite/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`) is a white rounded "F" on a dark graphite gradient, with an orange dot where the lower bar of the F would be. Everything in this system derives from it:

| Icon element | Measured color | Role in the UI |
|---|---|---|
| Background, top | `#2C2C2E` | Graphite, matches iOS dark `tertiarySystemBackground` |
| Background, center | `#1C1C1D` | Matches iOS dark `secondarySystemBackground` (`#1C1C1E`) |
| Background, bottom | `#0C0C0D` | "Ink", near black |
| The "F" | `#FFFFFF` | Primary text on dark |
| The dot | `#FF7A2F` | **Focus Orange**, the only brand color |

Two consequences:

- The icon's grays are already Apple's dark system grays, so **use semantic system colors for every surface and text**. Do not define custom grays.
- The **orange dot** is the brand motif: a single point of focus. Orange marks the one thing that matters on a screen (the primary action, an active state), never decoration.
- The F has fully rounded terminals, which echoes **SF Pro Rounded**. Use the rounded design for a few brand moments (see §4), not for body text.

## 3. Color

### Tokens

Define these in the asset catalog (Any / Dark appearances), never as hex literals in Swift.

| Token | Light | Dark | Use |
|---|---|---|---|
| `AccentColor` (Focus Orange) | `#D4571A` | `#FF7A2F` | App tint: primary actions, active state, the focus dot, toggles, links |
| `Ink` | `#0C0C0D` | `#0C0C0D` | Text and glyphs placed on a **solid** orange fill |
| `GraphiteTop` | `#2C2C2E` | `#2C2C2E` | Top stop of the brand gradient |
| `GraphiteBottom` | `#0C0C0D` | `#0C0C0D` | Bottom stop of the brand gradient |

Everything else is a system semantic color: `.primary`, `.secondary`, `.tertiary`, `Color(.systemBackground)`, `Color(.secondarySystemBackground)`, `Color(.systemGroupedBackground)`, `.red` for destructive actions, `.green` only for a confirmed success.

Why the light variant is darker: `#FF7A2F` has only 2.6:1 contrast against white. `#D4571A` reaches 4.1:1 against white and 3.6:1 against grouped gray (`#F2F2F7`), enough for tinted controls, icons and bold labels. In dark mode, `#FF7A2F` reaches 6.5:1 against `#1C1C1E`.

### Rules

- **Dark mode is the reference look** (it is the icon). Light mode must also work, so follow the system appearance and do not force `.preferredColorScheme(.dark)`.
- **Orange budget:** at most one orange element that draws the eye per screen, plus small state indicators. If a screen has two orange buttons, one of them is wrong.
- Text on a **solid** orange fill uses `Ink`, not white (white on `#FF7A2F` is 2.6:1). On a Liquid Glass button tinted orange, let the system pick the label color.
- The brand gradient (`GraphiteTop` → `GraphiteBottom`, top to bottom) is allowed only on brand surfaces: onboarding hero, service tiles, the empty-state illustration. Never behind a list or behind text-heavy content.
- Do not reuse Instagram's colors. Instagram content inside the WebView keeps its own look; FocusLite chrome stays graphite and orange.

## 4. Typography

- **SF Pro through text styles only**: `.largeTitle`, `.title2`, `.headline`, `.body`, `.subheadline`, `.footnote`, `.caption`. No fixed point sizes, so Dynamic Type works everywhere.
- Weights: `.regular` for body, `.semibold` for headlines and buttons, `.bold` only for large titles. No `.black` or `.heavy`.
- **SF Pro Rounded** (`.fontDesign(.rounded)`) is reserved for brand moments: the onboarding title, the Post Mode countdown, and large numbers. Everything else uses the default design.
- Numbers that change (countdown, durations) use `.monospacedDigit()` so they do not jitter.
- All UI strings are in French, short, and use "tu" (see existing strings: "Tu as décidé de t'en passer. Tiens bon."). Sentence case, no exclamation marks, no emoji.

## 5. Liquid Glass

Liquid Glass is the material of iOS 26 and later: a translucent, refracting layer for **controls and navigation that float above content**. FocusLite targets **iOS 26.0**, so use the glass APIs directly, with no `#available` checks and no pre-glass fallback. Standard components adopt glass by themselves.

> Do not invent APIs. The ones named here are the SwiftUI Liquid Glass APIs introduced with iOS 26. Anything added in a later SDK would raise the deployment target, so do not use it without asking.

### 5.1 Where glass goes

| Glass | Never glass |
|---|---|
| Navigation bars and toolbars (automatic) | List rows, cards, and any content |
| Sheets and their detents (automatic) | The Instagram WebView content |
| Menus, alerts, context menus (automatic) | Backgrounds of whole screens |
| Floating controls: the toast, the Post Mode capsule, a floating primary button | Glass placed on top of other glass |

Content is the bottom layer. Glass is the layer above it. Two glass layers never stack.

### 5.2 Prefer the system

1. Use `NavigationStack`, `.toolbar`, `List` / `Form` with `.insetGrouped`, `.sheet`, `Menu`, `.alert`, `Toggle`. They are glass for free and stay correct across OS updates.
2. **Do not fight the system bars.** Remove custom bar backgrounds such as `.toolbarBackground(.visible, for: .navigationBar)` (currently in `BrowserView`): they replace the glass bar and the scroll edge effect with an opaque one.
3. Do not set `.presentationBackground(...)` on sheets; let the glass sheet show.
4. Group related toolbar items so they share one glass capsule, and keep each toolbar to at most two items per side.

### 5.3 Custom glass, when a floating control is needed

```swift
// A floating capsule (toast, Post Mode countdown)
content
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .glassEffect(.regular, in: .capsule)

// The one primary action of a screen
Button("Activer le blocage") { ... }
    .buttonStyle(.glassProminent)   // picks up the orange tint
    .controlSize(.large)

// Secondary actions
Button("Plus tard") { ... }
    .buttonStyle(.glass)

// Several glass elements close to each other: wrap them so they blend and morph
GlassEffectContainer(spacing: 12) { ... }
```

- `.glass` for secondary controls, `.glassProminent` for **the** primary action. Never two prominent buttons side by side.
- Tint glass only to carry meaning: `.regular.tint(.accentColor)` means "active / focus is on". Do not tint for decoration.
- Add `.interactive()` only to glass that the user touches (custom buttons), not to read-only capsules.
- When one glass shape turns into another (the "Mode Poster" button becoming the countdown capsule), use `.glassEffectID(_:in:)` inside a `GlassEffectContainer` with a `@Namespace`, so it morphs instead of cross-fading.

### 5.4 Reduce Transparency

The system turns glass opaque when Reduce Transparency is on. Custom glass must stay readable in that case, so never rely on the blurred content behind a control for contrast.

## 6. Shape, spacing, depth

- Corners are always **continuous** (`RoundedRectangle(cornerRadius:style: .continuous)`) or capsules. Nested shapes are concentric: inner radius = outer radius − padding.
- Radii: 12 pt for small tiles (48 pt service icon), 20 pt for cards, capsule for floating controls and buttons.
- Spacing on a 4 pt grid: 4, 8, 12, 16, 20, 24, 32. Screen margins follow the system (`List` and `.padding()` defaults, 16–20 pt). Minimum touch target 44 × 44 pt.
- No custom drop shadows. Depth comes from glass and system materials only.
- Icons are **SF Symbols** only, in the same weight as the text next to them. Prefer the outline variant in lists and toolbars, and the `.fill` variant for a state that is on (`hand.raised.fill` in the toast).

## 7. Motion

- Springs only: `.snappy` for small state changes (toast in and out), `.smooth` for layout and morphs. No linear or ease-in-out timing curves, no bounce above the system default.
- Transitions: `.move(edge:)` combined with `.opacity` for elements that enter from an edge; glass morphing for glass that changes shape.
- Use `.contentTransition(.numericText())` for numbers that change, and `.symbolEffect` sparingly (at most one per interaction).
- Haptics: `.sensoryFeedback(.success, ...)` when blocking turns on or Post Mode starts, `.warning` when a navigation is blocked. Nothing else.
- With Reduce Motion on, replace moves and morphs with plain opacity fades.

## 8. Screens

### Onboarding (`OnboardingView`)
Brand gradient background, a large rounded title, one line of explanation, the permission list as an `.insetGrouped` list, and one full-width `.glassProminent` button at the bottom. This is the only screen where the graphite gradient fills the background.

### Home (`HomeView`)
`NavigationStack` with a large title "FocusLite", an `.insetGrouped` list of services, and "Réglages" (`gearshape`) as a glass toolbar button. Each service row: a 48 pt continuous tile filled with the brand gradient and a white SF Symbol (a small echo of the app icon), title in `.headline`, detail in `.subheadline` `.secondary`, and a trailing chevron in `.tertiary`. The tile is not orange; orange is kept for state. When blocking is on, a small orange dot (8 pt circle) may sit next to the title, the only status indicator on this screen.

### Settings (`SettingsView`, sheet)
A system `Form`, grouped sections, standard toggles (tinted orange by the accent), footers for explanations. No custom styling beyond the accent. Destructive actions use `role: .destructive`.

### Instagram browser (`BrowserView`)
The WebView fills the screen and scrolls under the glass navigation bar. The bar holds only FocusLite actions: "Accueil" (`square.grid.2x2`) on the leading side, Post Mode on the trailing side. No bottom bar: Instagram's own bar handles navigation.

- **Toast** ("Reels bloqués"): a glass capsule at the top, `hand.raised.fill` + text in `.subheadline.weight(.semibold)`, enters with `.move(edge: .top)` + `.opacity`, disappears on its own after about 2 s.

### Post Mode (`PostModeViews`)
- Off: a "Mode Poster" glass toolbar button (`plus.app`).
- On: the button morphs into a capsule tinted orange with `timer` and the countdown in rounded monospaced digits. Stopping stays behind a `Menu` ("Terminer maintenant", `stop.circle`) so a stray tap cannot end it.
- In Settings, the same states appear as a standard `Section` with `LabeledContent`.

### Shields (`ShieldConfigurationExtension`)
Shields cannot use SwiftUI or glass. Use `backgroundBlurStyle: .systemThickMaterial`, SF Symbol icon, system label colors for title and subtitle, and the brand accent instead of `.systemBlue`:

| Group | Icon | Primary button | Secondary |
|---|---|---|---|
| Redirect (Instagram) | `hourglass` | "Ouvrir FocusLite", background Focus Orange, label `Ink` | "Fermer", label Focus Orange |
| Hard block (TikTok…) | `nosign` | "Fermer", background `.systemGray`, label white | none |

Pass colors as `UIColor(named: "AccentColor")` from the asset catalog, which must then be a member of the extension target. Keep the extension minimal: no images beyond SF Symbols.

### Notifications
Plain system notifications: short French title, one-line body, no emoji. The app icon provides the brand.

## 9. Accessibility checklist

- Dynamic Type up to the accessibility sizes without truncating key actions (let rows grow; switch `HStack` to `VStack` at accessibility sizes if needed).
- Every icon-only control has a French `accessibilityLabel` (see `PostModeToolbarItem`).
- Contrast: 4.5:1 for text, 3:1 for icons and control boundaries, checked in both appearances and with Increase Contrast.
- Reduce Transparency, Reduce Motion and Bold Text all leave the UI readable and usable.

## 10. Do and don't

**Do**
- Start from a system component, and add custom styling only if the system one cannot do the job.
- Keep one focal point per screen, in orange.
- Let content scroll under glass bars.
- Keep French copy short, calm and encouraging.

**Don't**
- Invent Apple APIs, or use an API newer than iOS 26 without asking.
- Put glass on content, stack glass on glass, or tint glass for decoration.
- Hard-code hex colors in Swift, add custom shadows, or use custom fonts.
- Add streaks, scores, badges, confetti or any engagement mechanic: this app is here to reduce screen time, not to earn it.
- Copy Instagram's look or duplicate its navigation in native UI.
