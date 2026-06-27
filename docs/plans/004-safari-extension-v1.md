# Plan 004: Safari Web Extension v1 — clean the current page's link from the toolbar

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. Honor the STOP
> conditions — do not improvise. When done, update this plan's status row in
> `docs/plans/README.md`.
>
> **Read `docs/plans/SEED.md` first** — the eight standing LinkClean decisions. This
> plan records the Safari-specific answers; "SEED §N" points there for shared rationale.
>
> **This is a design + spike + handoff plan, not a pure code plan.** Target creation,
> the App Group capability, and signing are **Xcode-GUI work the maintainer (Ken) must
> do** (iOS `CLAUDE.md`: "Hand off … creating targets, configuring App Groups,
> entitlements, signing, capabilities"). The executor writes the *web assets, the native
> handler, the analytics case, and tests*; it does **not** create the target. The split
> is spelled out in "Handoff split" below. **Phase 0 is a gate** — do not start Phase 1
> until the seam is proven on a real device and the numbers are reported.
>
> **Drift check (run first)** — the Xcode-GUI handoff is **DONE** (target created
> 2026-06-26). Confirm the scaffold is intact and Phase 0 hasn't started:
> ```
> grep -n "case actionCleanSucceeded\|case intentCleanSucceeded\|case qrScanSucceeded" apps/ios/LinkClean/LinkCleanKit/Sources/LinkCleanCore/AnalyticsEvent.swift
> test -f apps/ios/LinkClean/LinkCleanSafariExtension/SafariWebExtensionHandler.swift && grep -c "echo" apps/ios/LinkClean/LinkCleanSafariExtension/SafariWebExtensionHandler.swift
> ```
> Expect: the three clean cases exist; the handler file exists and still contains the
> template **"echo"** stub (count ≥ 1 → Phase 0 not yet done). If the handler no longer
> echoes, Phase 0/1 is partly done — read "Current state of the target" below and the
> live files before proceeding.

## Status

- **State**: **Handoff DONE** (2026-06-26) — target `LinkCleanSafariExtension` created,
  App Group + `LinkCleanKit` linked, template scaffold present (echo stub). **Next:
  Phase 0** — swap the echo handler for a real clean and prove the device round-trip.
- **Priority**: P2 — a new *acquisition surface*, not a wedge-deepener (decision 1 is honest about this)
- **Effort**: M for the build, **+ a Phase 0 spike gate** (the JS↔native seam is unproven on this codebase)
- **Risk**: MED — new target *type* + a new cross-process seam. The engine reuse itself is LOW (the cleaner is already `nonisolated`, `Sendable`, extension-proven).
- **Depends on**: none
- **Category**: direction (feature) — new OS surface (growth-roadmap §4 S2 v1)
- **Target**: next feature release (1.3 candidate)
- **Planned at**: commit `07d8027`, 2026-06-26

## Why this matters

The share sheet, QR, App Intents, and the action extensions all require the user to
*leave* the page first. **Safari is where dirty links are born** — a toolbar button that
cleans the current page's URL in place is the shortest path from "I'm looking at a
tracked link" to "I have the clean one," and it is a **new acquisition + retention loop**:
a surface in Safari is discovered by people who never opened the app, and the App Store
listing gains a "Safari extension" ASO facet.

**Be honest about what this is (SEED §1).** The free competitor (Clean Links) already
ships a Safari extension for free (`docs/strategy/competitor-clean-links.md:53,113`), so a
Safari surface is **parity / distribution, not differentiation** — the wedge stays
formats / on-device AI / history-depth. What keeps v1 legitimate as a *free* feature
rather than a weak Pro gate is that **v1 is a manual popup cleaner, not auto-strip**.
Auto-strip on navigation (declarativeNetRequest) is v2 — Pro-eligible, deferred, and
needs its own `regexSubstitution` spike (growth-roadmap §4 S2 v2). This plan is v1 only.

North-star tie (kpis §0/§6): more surfaces → more clean opportunities per day → exports
per active user; a new surface also feeds the surface-mix diagnostic.

## The architecture decision (the load-bearing call)

A Safari Web Extension's popup is **JavaScript/HTML**, but LinkClean's cleaning catalog is
**Swift** (`LinkCleanCore`). Two ways to bridge:

1. **Keep cleaning in Swift; the popup relays via native messaging.** ✅ **Chosen.** The
   popup sends the active-tab URL to the extension's native handler
   (`SafariWebExtensionHandler`) via `browser.runtime.sendNativeMessage(...)`; the handler
   runs the existing `URLCleaner` and returns the cleaned string. The catalog stays in one
   place — **zero drift**, the engine is already `nonisolated`/`Sendable`, and the privacy
   posture is unchanged (everything runs on-device).
2. Port the catalog to JS and clean in the popup. ❌ **Rejected.** Reintroduces **catalog
   drift** — a recurring failure mode this codebase explicitly guards against
   (`docs/strategy/experiment-swiftwasm-landing-demo.md` exists precisely to avoid a
   hand-ported cleaner). A privacy/correctness app must not have two diverging catalogs.

**Verified (2026-06-26):** native messaging between a Safari web extension and its
containing app's native handler **is supported on iOS**, not just macOS. Authoritative
Apple sources for the executor to read before Phase 0:
- `/documentation/safariservices/messaging-between-the-app-and-javascript-in-a-safari-web-extension`
- `/documentation/safariservices/messaging-a-web-extension-s-native-app` (sample code)
- WWDC21 "Meet Safari Web Extensions on iOS"; WWDC26 session 216 "Create web extensions for Safari" (native messaging across platforms).

The native entry point is `NSExtensionRequestHandling.beginRequest(with:)` on the
generated `SafariWebExtensionHandler` class.

## The eight SEED decisions

1. **Strategy fit — acquisition surface, *not* a wedge (honest).** New entry point in
   Safari; parity with a free competitor (`competitor-clean-links.md:113`). It earns its
   place as distribution + a screenshot-able "works right in Safari" story, not as
   differentiation. v1 is free because it's a manual *operation* on a new surface, and
   **no extension paywalls** is a standing rule (iap §9).
2. **Surfaces — a new surface (Safari), reusing the engine seam.** The native handler
   calls the same `URLCleaner` the app/action-extension/intents use. **Not** auto-strip
   (that's v2). Like the action extension, it's a short-lived process with a tight time
   budget, but the clean is **offline + instant** (no network, no model) so the budget is
   a non-issue. No short-link expansion (E4) in v1 — that's the one networked path and it
   stays opt-in/app-side (SEED §5).
3. **Free vs Pro — FREE, all of it.** No gate, no `PaywallTrigger`, no benefit-row change
   (no extension paywalls, iap §9; gate addition not operation, iap §6 rule 3). The popup
   offers the **free floor**: Clean → Copy / Share / Copy as Markdown. Pro *custom*
   templates in the popup are a deferred follow-on (maintenance notes), not v1.

   | Capability (popup) | Free | Pro |
   |---|---|---|
   | Clean the current page's URL | ✅ | ✅ |
   | Copy / Share the cleaned link | ✅ | ✅ |
   | Copy as Markdown (the free preset) | ✅ | ✅ |
   | Auto-strip on navigation (v2, DNR) | — deferred — | — deferred (Pro-eligible) — |

4. **Foundation Models — N/A.** No AI in v1.
5. **Privacy & determinism — the make-or-break section for this brand.** Request the
   **minimum** permission: `activeTab` + `nativeMessaging` **only**. **Never `<all_urls>`
   or broad `host_permissions`** — a privacy utility that can read every page you visit is
   self-refuting (and is exactly the auto-strip/v2 surface, deferred). `activeTab` grants
   the URL only when the user taps the toolbar button. The clean is deterministic and
   offline; the native handler **never logs the URL** (mirror the engine's no-logging
   posture). Nothing leaves the device.
6. **Analytics — one new typed case.** Add `safariCleanSucceeded(telemetry:)` mirroring
   `intentCleanSucceeded`/`qrScanSucceeded` (`AnalyticsEvent.swift:147,164`): same
   analytics-safe `CleanOutcome.Telemetry` (counts, kind ids, `domain` host, `unwrapped`,
   `expanded` — no URL, no param names). Add the case + both switches + a test
   (analytics-audit pattern, SEED §6). **Emission caveat:** the SDK must be initialized in
   the extension's process to fire — mirror however the action extension does it; if the
   action extension does **not** initialize TelemetryDeck in-process today, ship v1 with
   the clean working and the typed case + test in place, and treat live emission as a
   tracked follow-up (note it in the status row). The enum case + test are the
   fast-lane-checkable deliverable; runtime emission is best-effort.
7. **Architecture fit.** New `LinkCleanSafariExtension/` target (web assets +
   `SafariWebExtensionHandler.swift`) mirroring the existing extension targets'
   directory + Info.plist + entitlements pattern. The handler is a **thin adapter**: parse
   the message, call `URLCleaner`/`TemplateRenderer`, return a string — no business logic
   of its own. It links `LinkCleanCore` (cleaner, renderer, analytics enum) and
   `LinkCleanData` (`EntitlementStore`, only if v1 ever needs the Pro bit — v1 doesn't gate,
   so it may not). Domain types ship identifiers; the popup's *visible* strings are web
   assets localized in the web layer (decision in Step 5), not the app's xcstrings.
8. **Verification.** The cleaning logic is already covered by `LinkCleanCoreTests` (fast
   lane). New *unit-testable* logic is just the analytics case (fast lane) and any
   message-shape mapping you extract into a `nonisolated` helper. The JS/Safari/native
   round-trip is **not** unit-testable — it's covered by the Phase 0 spike + a manual
   device QA matrix (test plan). Compile gate for the app target =
   `xcodebuild build-for-testing -scheme LinkCleanTests` (the app-test sim runner is
   flaky — a "runner hung" is infra, not a failure).

## Current state (excerpts — confirm during recon)

**The engine the handler will call** (`LinkCleanCore/URLCleaner.swift`) — pure `enum`, all
`static`, `nonisolated`, no isolation barrier:

```swift
// :47  one-liner — cleans with the default removal set for the URL's host
public static func clean(_ urlString: String) -> String
// :51  with an explicit removal set
public static func clean(_ urlString: String, removing parameters: Set<String>) -> String
// :75  full analyzed result (cleaned string + analytics-safe Telemetry + Display names)
public static func outcome(
    for input: String, removing parameters: Set<String>,
    referenceNames: Set<String> = ReferenceParameterCatalog.names,
    wrappers: [String] = [], stripTextFragment: Bool = true,
    expanded: Bool = false, arrivedFromHost: String? = nil
) -> CleanOutcome
// :12  validate before cleaning
public static func isValidURL(_ urlString: String) -> Bool
```

Minimal handler call: `guard URLCleaner.isValidURL(raw) else { … }; let o = URLCleaner.outcome(for: raw, removing: TrackingParameterCatalog.defaultRemovalSet(forHost: URLCleaner.ruleHost(of: raw)))` → `o.cleaned` is the string, `o.telemetry` feeds analytics. (For Markdown: `TemplateRenderer.render(...)` in `LinkCleanCore/TemplateRenderer.swift`, also `nonisolated` static; render with the cleaned link and a title that **falls back to the host** so the preset never produces a broken `[](url)`.)

**App Group + Pro read** (only if v1 ends up needing the Pro bit — it doesn't gate, so this
may be unused in v1):
- `LinkCleanCore/AppGroup.swift:11` — `public static let identifier = "group.com.ken0nek.LinkClean"`.
- `LinkCleanData/EntitlementStore.swift:16-33` — `EntitlementStore().current()` returns `.free`/`.pro`, fail-closed, reads the App Group suite.

**Analytics insertion points** (`LinkCleanCore/AnalyticsEvent.swift`): the surface-tagged
clean case to mirror is `case intentCleanSucceeded(surface: IntentSurface, telemetry:)`
(`:147`) and `case qrScanSucceeded(telemetry:)` (`:164`). Add the new case beside them,
then a `signalName` arm (`:347` block — e.g. `case .safariCleanSucceeded: "Safari.Clean.succeeded"`)
and a `parameters` arm (`:373` block — copy `homeURLCleaned`'s telemetry mapping at
`:375-386`, minus `source`). Note the comment at `:394-398`: TelemetryDeck sets a
process-level default `surface` parameter — if you key anything `surface`, rename it
(the intent event uses `intentSurface` to dodge this collision).

**The existing extension-target pattern** (the shape Ken mirrors in the GUI):
- `LinkCleanAction/Info.plist` — an `NSExtension` dict with `NSExtensionPointIdentifier`
  (`com.apple.ui-services` for the action ext; **the Safari target's is
  `com.apple.Safari.web-extension`**, generated by Xcode's template — don't hand-author it).
- `LinkCleanAction/LinkCleanAction.entitlements` — just the App Group:
  ```xml
  <key>com.apple.security.application-groups</key>
  <array><string>group.com.ken0nek.LinkClean</string></array>
  ```
- Bundle-id convention: `com.ken0nek.LinkClean.LinkClean<Name>`; targets are embedded in
  the app's "Embed App Extensions" build phase and declared as `PBXNativeTarget` with
  productType `com.apple.product-type.app-extension` in
  `apps/ios/LinkClean/LinkClean.xcodeproj/project.pbxproj`.

## Handoff split — Ken's GUI part is DONE

**✅ Ken (Xcode GUI), completed 2026-06-26 — verified in the working tree:**
1. Target `LinkCleanSafariExtension` created (app-extension, embedded in the app's "Embed
   Foundation Extensions" phase). Bundle id `com.ken0nek.LinkClean.LinkCleanSafariExtension`;
   `SafariServices` linked.
2. App Group `group.com.ken0nek.LinkClean` present in
   `LinkCleanSafariExtension/LinkCleanSafariExtensionRelease.entitlements`.
3. `LinkCleanKit` linked to the target (pbxproj `packageProductDependencies`) → `import
   LinkCleanCore` resolves from the handler.

**This work is uncommitted on the working tree** (new files staged/added, `project.pbxproj`
modified). Don't expect a commit; don't commit unless asked.

**Everything remaining is code (Phase 0 + Phase 1 below).** No more GUI handoff is needed
*unless* Phase 0 reveals a missing capability — then stop and ask Ken.

### Current state of the target (what Xcode generated)

Xcode scaffolded a **working default Safari web extension** under
`apps/ios/LinkClean/LinkCleanSafariExtension/`:
- `SafariWebExtensionHandler.swift` — the **echo stub** (`beginRequest` returns
  `["echo": message]`). Imports `SafariServices` only. This is what Phase 0 replaces.
- `Resources/manifest.json` — MV3, `default_popup: popup.html`, **`permissions: []`** (empty),
  and a **placeholder content script** `content.js` matching `*://example.com/*`.
- `Resources/popup.{html,css,js}`, `background.js`, `content.js` — default template UI/glue.
- `Resources/_locales/en/messages.json` — i18n file (where popup strings live, Step 5).
- `Resources/images/*`, `Info.plist` (`com.apple.Safari.web-extension`).

**Three cleanups the build needs (fold into Phase 1; none cross the privacy line — the
template did *not* request `<all_urls>`):**
1. `manifest.json` `permissions`: add **`"activeTab"`** (needed to read the active tab's
   URL). Safari routes `sendNativeMessage` to the container without a `nativeMessaging`
   permission — confirm in Phase 0; add it only if the round-trip needs it. **Never add
   `host_permissions` / `<all_urls>`.**
2. Remove the **placeholder content script** (`content.js` + the `content_scripts` block):
   v1 reads the URL in the popup via `activeTab` + `tabs.query`, so no content script is
   needed. (If Phase 0 shows the popup *can't* read the URL without one, add a *narrowly
   scoped* injected script under `activeTab` — still never `<all_urls>`.)
3. Replace the **echo handler** body (Phase 0/Step 2).

## Scope

**In scope** (executor):
- `LinkCleanSafariExtension/Resources/manifest.json` (MV3; `activeTab` + `nativeMessaging` only)
- `LinkCleanSafariExtension/Resources/popup.{html,css,js}`
- `LinkCleanSafariExtension/Resources/background.js` (relay popup ↔ native)
- `LinkCleanSafariExtension/SafariWebExtensionHandler.swift` (the native adapter body)
- `LinkCleanKit/Sources/LinkCleanCore/AnalyticsEvent.swift` (add `safariCleanSucceeded`)
- `LinkCleanTests/…/AnalyticsEventTests.swift` (extend)
- (optional) a Settings/onboarding pointer telling users to enable the extension

**Out of scope (do NOT touch):**
- **declarativeNetRequest / auto-strip on navigation** — that's v2 (Pro-eligible), a
  separate plan with its own `regexSubstitution` spike. STOP if tempted.
- **Porting the catalog to JS / any cleaning logic in JS** — cleaning stays in Swift
  (the architecture decision). The popup must not contain a parameter list.
- **Broad host permissions** (`<all_urls>`, `host_permissions`) — `activeTab` only.
- Any `ProGate` / `PaywallTrigger` / `PaywallView` change — v1 is free.
- The action extensions, App Intents, QR, Foundation Models.
- Short-link expansion (E4) inside the extension.

## Phase 0 — the spike (GATE; prove the seam, report numbers, then stop)

A throwaway proof on a **real iOS device** (the simulator's Safari-extension story is
unreliable; measure on hardware). Build the smallest thing that answers: *does the popup
get the URL, reach Swift, and get a cleaned string back, fast?*

1. **The scaffold already does a round-trip** (popup → `sendNativeMessage` → handler →
   echo). Phase 0 is to make that echo a *real clean*, minimally:
   - `manifest.json`: add `"activeTab"` to `permissions`; keep `default_popup`. (No host
     permissions; remove the `example.com` content script per the cleanups above.)
   - `popup.js`: on load, `browser.tabs.query({active: true, currentWindow: true})` → take
     `tabs[0].url` → `browser.runtime.sendNativeMessage("application.id", { url })` →
     render the response in the popup. (First confirm the *existing* echo reaches the
     handler before changing it — that isolates "messaging works" from "my clean works".)
   - `SafariWebExtensionHandler.beginRequest(with:)`: `import LinkCleanCore`; replace the
     `["echo": message]` body with: read the message dict's `url`, call
     `URLCleaner.clean(url)`, return `[ "cleaned": cleaned ]`.
2. On device: open a page with a tracked URL (e.g. anything with `?utm_source=…`), tap the
   toolbar button, confirm the popup shows the **cleaned** URL.
3. **Report before Phase 1:** (a) does `sendNativeMessage` round-trip on device? (b)
   rough latency tap→result (target: feels instant, < ~300 ms); (c) does `activeTab`
   yield the URL without any host permission prompt? (d) confirm `URLCleaner` is callable
   from the handler (import resolves, no isolation error).

**STOP and report (do not improvise) if:** the round-trip fails on device; latency is
user-hostile; `activeTab` can't read the URL without broad permissions; or the handler
can't link `LinkCleanCore`. If the seam is fundamentally unavailable, the fallback is the
*rejected* JS-port — **do not adopt it without maintainer sign-off** (it changes the whole
privacy/drift calculus). Bring the numbers back.

## Phase 1 — build v1 (only after Phase 0 passes)

### Step 1 — manifest + popup shell
Finalize `manifest.json` (MV3, `activeTab` + `nativeMessaging`, toolbar `action` →
`popup.html`, a `background.js` service worker if the relay needs one). Build `popup.html`
+ `popup.css` matching a clean, native-feeling card (a small, legible result + three
buttons). No catalog, no cleaning logic here.
**Verify**: extension loads in Safari (device), toolbar button shows the popup.

### Step 2 — the native handler (the adapter)
Implement `SafariWebExtensionHandler.beginRequest(with:)`:
- Decode the message `{ url, title? }`.
- `guard URLCleaner.isValidURL(url)` → on failure return `{ error: "invalidInput" }`.
- `let o = URLCleaner.outcome(for: url, removing: TrackingParameterCatalog.defaultRemovalSet(forHost: URLCleaner.ruleHost(of: url)))`.
- Build the response: `{ cleaned: o.cleaned, markdown: <TemplateRenderer markdown with title ?? host> }`.
- Emit `AnalyticsEvent.safariCleanSucceeded(telemetry: o.telemetry)` **if** the SDK is
  initialized in-process (decision 6 caveat); never log the URL.
**Verify**: `xcodebuild build-for-testing -scheme LinkCleanTests …` → `EXIT: 0` (app
target unaffected); the extension target compiles.

### Step 3 — popup behavior (Clean / Copy / Share / Markdown)
`popup.js`: get the active-tab URL (`activeTab`), send to native, render `cleaned`. Wire:
- **Copy** → `navigator.clipboard.writeText(cleaned)`.
- **Copy as Markdown** → copy the `markdown` field from the response.
- **Share** → `navigator.share?.({ url: cleaned })` where available, else hide the button.
Show a calm "already clean" state when `cleaned === url`.
**Verify**: manual on device — Copy, Markdown, Share all work; "already clean" shows for a
trackerless URL.

### Step 4 — analytics case + test
Add `case safariCleanSucceeded(telemetry: CleanOutcome.Telemetry)` to `AnalyticsEvent`
beside `intentCleanSucceeded` (`:147`); add the `signalName` arm
(`"Safari.Clean.succeeded"`) and the `parameters` arm (copy `homeURLCleaned`'s telemetry
mapping minus `source`). Extend `AnalyticsEventTests` to assert the new signal name +
parameter keys (mirror the existing clean-event tests).
**Verify**: `cd apps/ios/LinkClean/LinkCleanKit && swift test` → all pass incl. the new
assertion.

### Step 5 — popup localization (en/ja/de)
The popup's visible strings live in the **web layer** (a small `_locales/<lang>/messages.json`
per the WebExtension i18n convention + `browser.i18n.getMessage`), **not** the app's
`Localizable.xcstrings` (the popup is HTML, not SwiftUI). Provide en / ja / de for the
handful of strings (Clean, Copy, Copy as Markdown, Share, "Already clean"). Match the
app's vocabulary (e.g. ja "クリーン" / de "Bereinigt") for consistency.
**Verify**: switching the device language flips the popup strings.

### Step 6 — in-app discovery pointer (optional but recommended)
Safari extensions are invisible until enabled in Settings. Add a small Settings row (and/or
an onboarding mention) — "Turn on the Safari extension" — pointing the user to
Settings → Apps → Safari → Extensions, or use `SFSafariApplication`/`ASWebAuthentication`
deep links where available. Reuse the existing "give a button, not a location" pattern from
the History "Turn On History" affordance. Keep it free, no paywall.
**Verify**: `build-for-testing` → `EXIT: 0`.

## Test plan

- **Fast lane (Core):** the new `AnalyticsEvent.safariCleanSucceeded` case — signal name +
  parameter keys, no PII (model after the existing `intentCleanSucceeded`/`qrScanSucceeded`
  tests in `AnalyticsEventTests`). The cleaning itself is already covered by
  `URLCleanerTests` — do **not** re-test cleaning here.
- **Not unit-testable (manual device QA matrix — record pass/fail in the status row):**
  enable the extension; clean a `?utm_source=` URL; Copy; Copy as Markdown (with and
  without a page title → never a broken `[](url)`); Share; a redirect-wrapper URL
  (`expanded`/`unwrapped` telemetry path); a trackerless URL ("already clean"); confirm
  **no** broad-permission prompt appears (privacy check); confirm the URL is never written
  to any log.
- Gate: `cd LinkCleanKit && swift test` (fast) + `build-for-testing` (app compile).

## Done criteria

ALL must hold:

- [ ] Phase 0 spike report exists (round-trip works on device + latency number + `activeTab` confirmed).
- [ ] `cd apps/ios/LinkClean/LinkCleanKit && swift test` → all pass, incl. the new `safariCleanSucceeded` assertion.
- [ ] `xcodebuild build-for-testing -project apps/ios/LinkClean/LinkClean.xcodeproj -scheme LinkCleanTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'` → `EXIT: 0`.
- [ ] `grep -i "all_urls\|host_permissions" apps/ios/LinkClean/LinkCleanSafariExtension/Resources/manifest.json` → **no matches** (privacy: `activeTab` only).
- [ ] `grep -rin "utm_\|fbclid\|gclid\|removalSet\|trackingParam" apps/ios/LinkClean/LinkCleanSafariExtension/Resources/` → **no matches** (no catalog/cleaning logic in JS).
- [ ] No `ProGate` / `PaywallTrigger` / `PaywallView` files modified (`git status`).
- [ ] Manual device QA matrix completed and recorded.
- [ ] `docs/plans/README.md` status row for 004 updated.

## STOP conditions

Stop and report (do not improvise) if:

- The Phase 0 seam fails on a real device, or latency is user-hostile.
- You are tempted to port the catalog / any cleaning logic into JS (the rejected path).
- You are tempted to add `declarativeNetRequest` auto-strip — that is v2, a separate plan.
- You are tempted to request `<all_urls>` or any `host_permissions` — `activeTab` only;
  a privacy app reading every page is the line we don't cross.
- Wiring anything requires a `ProGate` / paywall change — v1 is free.
- The target doesn't exist yet / the App Group isn't attached — that's Ken's GUI handoff,
  not executor work; stop and request it.

## Maintenance notes

- **v2 (the real Pro question):** auto-strip on navigation via `declarativeNetRequest`
  redirect rules. Needs a spike on iOS Safari's `regexSubstitution` limits (growth-roadmap
  §4 S2 v2) **and** a fresh look at whether it's even worth gating Pro — the free
  competitor ships Safari auto-strip free, so it may be a weak gate (SEED §1). Decide at
  plan-time, not now.
- **Custom Pro templates in the popup:** deferred. v1 ships the free Markdown floor. If
  added later, read active templates from the App Group (the in-extension picker pattern
  from "copy-as-you-want" already exists) and remember: no extension paywall — surface a
  Pro user's templates, don't sell inside the popup.
- **Reviewer scrutiny:** (1) permission minimalism — `activeTab` + `nativeMessaging`,
  nothing broader; (2) the URL never enters a log or analytics (only bucketed telemetry);
  (3) the handler is a thin adapter with no catalog of its own; (4) Markdown never renders
  a broken `[](url)` (title falls back to host).
- **Analytics emission** may land as a follow-up if the extension process doesn't init the
  SDK — keep the typed case + test regardless so the taxonomy is ready (analytics-audit).
