# Plan 005: Safari Web Extension v2 — auto-strip tracking params on navigation

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. Honor the STOP
> conditions — do not improvise. When done, update this plan's status row in
> `docs/plans/README.md`.
>
> **Read `docs/plans/SEED.md` first** — the eight standing LinkClean decisions. This
> plan records the v2-specific answers; "SEED §N" points there for shared rationale.
>
> **This is a design + spike plan.** **Phase 0 is a hard gate**: iOS Safari's
> `declarativeNetRequest` (DNR) is *unproven* for query-param stripping on this
> codebase, and Apple's docs/forums are inconclusive. Do not build Phase 1 until the
> DNR round-trip is proven on a real device and the numbers are reported.
>
> **Drift check (run first):**
> ```
> grep -c "declarativeNetRequest\|host_permissions" apps/ios/LinkClean/LinkCleanSafariExtension/Resources/manifest.json
> grep -rn "DNRRuleGenerator" apps/ios/LinkClean/LinkCleanKit/Sources/LinkCleanCore/ | head
> ```
> Expect **both empty / count 0** at the start (v1 ships `activeTab`+`nativeMessaging`
> only, no DNR). If `declarativeNetRequest` already appears in the manifest, Phase 0/1
> is partly done — read the live files before proceeding.

## Status

- **State**: **SHELVED at Phase 0** (2026-06-27) — the throwaway spike ran on Ken's device,
  but the **core strip test was never reached** (we stopped at the host-permission step), so
  the load-bearing feasibility question is **still unproven**. Direction pivoted to polishing
  Safari **v1** instead. **Findings + the exact resume point are in "Phase 0 spike — device
  findings" below.** Safari v1 (plan 004) is built + device-verified (commits `86c0d61`,
  `4880bf1`); this extends that target.
- **Priority**: P2 — extends the Safari surface with a "set it and forget it" cleaner;
  a retention/ambient-value lever, **not** a wedge.
- **Effort**: M for the build, **+ a Phase 0 DNR feasibility spike** (the load-bearing risk).
- **Risk**: **MED-HIGH** — hinges on iOS Safari honoring a DNR `redirect`+`removeParams`
  rule (unconfirmed); introduces a broad **but blind/declarative** host permission. The
  engine reuse is LOW risk (the catalog is already pure Swift).
- **Depends on**: plan 004 (Safari v1 — the target, popup, App Group). Built/unshipped.
- **Category**: direction (feature) — new OS-surface behavior (growth-roadmap §4 S2 v2).
- **Target**: a feature release after v1 ships.
- **Planned at**: commit `4880bf1`, 2026-06-27.

## Phase 0 spike — device findings (2026-06-27, SHELVED before the gate)

A throwaway DNR spike ran on a physical iPhone (iOS 26). **The core gate — does iOS Safari
honor `removeParams` and strip a param on navigation? — was NEVER reached** (we stopped at
the host-permission step). So v2's load-bearing feasibility is **still unproven**. What the
spike *did* nail down:

1. **`updateEnabledRulesets` works** — a static ruleset enables programmatically from the
   popup with no host access (`ruleset: ENABLED` confirmed on device).
2. **`permissions.request({origins})` is a no-op on iOS** — it resolves `false`, shows no
   prompt. A Safari web extension gets **no programmatic host grant**; host access is granted
   **only** through Safari's native UI. (So a Phase-1 opt-in can't be a simple in-popup
   button — it must route the user to Settings / the native per-site flow.)
3. **Grant path (native):** Settings → Apps → Safari → Extensions → LinkClean → **All
   Websites → Allow** (defaults to "Ask"); or tap the extension on a page → "would like to
   access [site]" modal → Always Allow on Every Website.
4. **`optional_host_permissions` DOES surface on iOS** — it appears on the extension's
   Settings page as a grantable **"All Websites → Ask"** row. So the plan's **optional,
   opt-in** host model (decision 5) **is feasible** — do **not** switch to non-optional
   `host_permissions`. (We nearly did; the Settings screenshot proved it unnecessary.)
5. **★ Privacy win — decision 5 vindicated + a competitive edge.** Because LinkClean is
   **DNR-only + `activeTab`** (no content script), iOS assigns it the *milder* permission
   class. Verbatim, side by side:
   - **LinkClean** → "**Browsing History** — Can see your browsing history on the current
     tab's webpage when you use the extension."
   - **Clean Links** (content scripts) → "**Webpage Contents and Browsing History** — Can
     read and alter sensitive information on webpages, **including passwords, phone numbers,
     and credit cards**…"
   The honest story ("it can't read your pages") is **literally true on iOS**, and our prompt
   is *gentler than the free competitor's*. **Keep v2 content-script-free** to preserve this.

**To resume — start exactly here:** re-create the spike (a `redirect` + `removeParams`
ruleset + the manifest perms below; see Scope), set LinkClean **All Websites → Allow**,
reopen the popup (state → `host perm: granted`), load
`https://example.com/?utm_source=test&keep=1`, and watch the **address bar** (NOT the popup's
"Cleaned link" — that's the v1 *manual* Swift clean, not DNR). `utm_source` gone → mechanism
proven, go to Phase 1. Survives even with All Websites = Allow → the optional grant isn't
reaching the DNR engine; only **then** try a non-optional `host_permissions` diagnostic.
Still open after that: reload/flash UX, `removeParams` case-sensitivity, and whether
`requestDomains` host-scoping works on iOS.

**The throwaway spike was reverted** from the working tree (v1 restored clean) so v1 polish
could proceed. It was: a hand-written `rules.json` (one `redirect` +
`removeParams:["utm_source"]`, `resourceTypes:["main_frame"]`), manifest
`declarativeNetRequest` + `optional_host_permissions:["*://*/*"]` + a disabled `auto_strip`
ruleset, and popup Enable/Disable/diag buttons.

## Why this matters

v1 is a **manual** popup cleaner — the user taps the toolbar button per link. v2 is the
**ambient** version: every navigation has its tracking query-params stripped with no tap,
no thought. That is the highest retention/value lever for the Safari surface — the
difference between "a tool I remember to use" and "a thing that just keeps my links clean."

**Be honest (SEED §1).** The free competitor (Clean Links) ships Safari auto-strip free
(`docs/strategy/competitor-clean-links.md`), so this is **parity / table-stakes, not
differentiation** — the wedge stays formats / history-depth. That is exactly why **v2 is
free** (decision 3). It earns its place as retention + a stronger "works in Safari" story,
not as a Pro lever.

## The architecture decision (the load-bearing call)

Auto-strip on navigation can be built two ways:

1. **`declarativeNetRequest` (DNR) with a ruleset *generated from the Swift catalog*.**
   ✅ **Chosen.** The extension declares a static `redirect` rule whose
   `queryTransform.removeParams` list is **generated at build time from
   `TrackingParameterCatalog`** — Swift stays the single source of truth, zero drift. DNR
   is **declarative and blind**: Safari evaluates and rewrites requests *without ever
   handing the extension a URL* (MDN: "these declarative rules enable the browser to
   evaluate and modify network requests **without notifying extensions about individual
   network requests**… extensions do not read the network requests"). So the extension
   cleans every page yet **sees none of them**.
2. **A content script / `webRequest` interceptor that cleans the URL in JS.** ❌
   **Rejected.** This is the *non-blind* path — it reads every page the user visits. For a
   privacy utility that is self-refuting, and it reintroduces a JS cleaning path (catalog
   drift). DNR exists precisely to avoid both.
3. **A hand-written `rules.json`.** ❌ **Rejected.** Reintroduces catalog drift — the
   recurring failure mode this codebase designs around. The rules must be *generated* from
   the Swift catalog, never authored by hand.

**The cost of choosing DNR — name it plainly:** DNR `redirect` rules **require broad host
access** (`host_permissions`, effectively `<all_urls>`) to match URLs across sites. That is
the permission v1 deliberately avoided. The reconciliation (decision 5): the access is
**declared optional and requested only at opt-in**, it uses the **transparent**
`declarativeNetRequest` permission (shown in the iOS prompt), and it is **blind** — so the
honest story is "LinkClean tells Safari to strip a fixed tracker list; it can't see your
browsing," not "LinkClean reads every page."

**Verified (2026-06-27, must re-confirm in Phase 0):** the mechanism is a `redirect` action
with `transform.queryTransform.removeParams`. iOS Safari's DNR support for `removeParams`
specifically is **not** confirmed by Apple's docs (Safari has known DNR gaps) — **this is
what Phase 0 proves.** Authoritative sources to read before Phase 0:
- MDN `declarativeNetRequest` (the `redirect`/`URLTransform`/`queryTransform` action; the
  permission model; the "blind" privacy guarantee).
- Apple: "Managing Safari web extension permissions"; Apple forums on Safari 16.4
  `declarativeNetRequest` (redirect actions require host access).
- WWDC23 "What's new in Safari extensions" (DNR on Safari).

## The eight SEED decisions

1. **Strategy fit — parity / retention, FREE, not a wedge (honest).** Ambient auto-clean
   on a surface a free competitor already covers. It earns its place as retention + a
   screenshot-able "cleans as you browse" story, not differentiation.
2. **Surfaces — the existing Safari extension, new *behavior* (on-navigation).** Reuses the
   v1 target. **Query-param removal only** — DNR is declarative and cannot express
   redirect-unwrapping (E1), fragment cleaning (E2), or short-link expansion (E4); those
   **stay in the v1 manual popup**. No new network egress (DNR is local).
3. **Free vs Pro — FREE, all of it.** No gate, no `PaywallTrigger`, no benefit-row change
   (no extension paywalls, iap §9; gate the *addition* not the *operation* — auto-strip
   only automates the free clean, iap §6 rule 3).

   | Capability | Free | Pro |
   |---|---|---|
   | Auto-strip tracking query-params on navigation | ✅ | ✅ |
   | Manual popup clean / Copy / Share / Markdown (v1) | ✅ | ✅ |
   | (No v2 Pro tier) | — | — |

4. **Foundation Models — N/A.** No AI. (Also out of scope by standing preference: on-device
   FM is deferred until iOS 27's private model cloud — see the memory note.)
5. **Privacy & determinism — the make-or-break section.** Four pins:
   - **Optional, opt-in host access.** Declare the host permission as **optional**
     (`optional_host_permissions`) and request it at runtime (`permissions.request`) **only
     when the user turns auto-strip on**. Result: the v1 manual popup keeps its clean
     **`activeTab`-only** profile, and a user who never enables auto-strip never grants
     `<all_urls>`.
   - **Transparent, not quiet.** Use `declarativeNetRequest` (shown in the iOS permission
     prompt), **not** `declarativeNetRequestWithHostAccess` (hidden). The user sees and
     grants it.
   - **Blind by construction.** DNR never exposes a URL to the extension; the handler/popup
     never logs one. Honest copy makes the blindness explicit.
   - **Off by default; deterministic.** Ships disabled. The strip list is the same
     finite catalog the rest of the app uses.
6. **Analytics — one new typed case, opt-in funnel only.** Add
   `safariAutoStripToggled(enabled: Bool)` (the discovery/activation signal). **There is no
   per-strip telemetry — DNR is blind, so we *cannot* count individual strips, and that is
   the privacy win, not a gap.** Emission caveat mirrors v1 (the extension process may not
   init the SDK): keep the typed case + test regardless; if the toggle state is mirrored to
   the App Group, the app can emit it app-side. Bucketed, no PII (analytics-audit pattern).
7. **Architecture fit.** New `DNRRuleGenerator` in `LinkCleanCore` (pure, `nonisolated`,
   fast-lane-tested) maps `TrackingParameterCatalog` → an array of DNR rule dicts → JSON.
   A **committed `rules.json`** in the extension's Resources is the build artifact; a
   fast-lane **drift-guard test** regenerates and asserts equality (fails if the catalog and
   the committed file diverge). The manifest gains `declarativeNetRequest` +
   `optional_host_permissions` + a `declarative_net_request` ruleset shipped **disabled**;
   `background.js` enables it (`updateEnabledRulesets`) from the stored opt-in state. Domain
   types still ship in Swift; no cleaning logic in JS.
8. **Verification.** The generator + drift guard run the **fast lane** (`swift test`). The
   DNR round-trip is **not** unit-testable — Phase 0 device spike + a manual QA matrix.
   Compile gate = `xcodebuild build-for-testing -scheme LinkCleanTests` (the app-test sim
   runner is flaky — a "runner hung" is infra, not a failure).

## Current state (excerpts — confirm during recon)

- **The catalog** (`LinkCleanCore/TrackingParameterCatalog.swift`):
  `defaultRemovalSet(forHost:)` returns the params to strip for a host;
  `enabledParameters(forHost:)` and the host-scoped definitions back it (see
  [catalog-default-false-positives] memory). The generator reads these.
- **The v1 extension** (`LinkCleanSafariExtension/`): `manifest.json` with
  `permissions: ["activeTab","nativeMessaging"]` (no host access); `background.js` (a stub
  today); the popup; `SafariWebExtensionHandler.swift`. The App Group
  `group.com.ken0nek.LinkClean` is attached.
- **Settings** (`LinkClean/Features/Settings/SettingsView.swift`): the v1 "Turn On Safari
  Extension" row (plan 004 Step 6) is the pattern to extend for the v2 status/explainer.

## Scope

**In scope** (executor):
- `LinkCleanKit/Sources/LinkCleanCore/DNRRuleGenerator.swift` (+ test in `LinkCleanCoreTests`)
- `LinkCleanSafariExtension/Resources/rules.json` (generated, committed)
- `LinkCleanSafariExtension/Resources/manifest.json` (DNR + optional host perms + ruleset)
- `LinkCleanSafariExtension/Resources/background.js` (enable/disable ruleset; request permission)
- `LinkCleanSafariExtension/Resources/popup.{html,js,css}` (the opt-in toggle + status)
- `LinkCleanSafariExtension/Resources/_locales/{en,ja,de}/messages.json` (new strings)
- `LinkClean/Features/Settings/…` (status row + explainer) + `Localizable.xcstrings`
- `LinkCleanCore/AnalyticsEvent.swift` (+ test) — `safariAutoStripToggled`

**Out of scope (do NOT touch):**
- **Porting cleaning logic to JS / hand-writing rules.json** — rules are *generated* from Swift.
- **Content scripts / `webRequest`** — the non-blind path. STOP if tempted.
- **`declarativeNetRequestWithHostAccess`** (the hidden permission) — use the transparent one.
- **Redirect-unwrap / fragment / short-link in DNR** — not expressible; stays in the v1 popup.
- **Any `ProGate` / `PaywallTrigger` / `PaywallView` change** — v2 is free.
- The v1 manual popup's `activeTab`-only behavior — must remain unchanged for non-opt-in users.

## Phase 0 — the spike (GATE; prove DNR on device, report, then stop)

A throwaway proof on a **real iOS device**. Build the smallest thing that answers: *does a
DNR `redirect`+`removeParams` rule actually strip a tracking param on navigation in iOS
Safari, and can we gate the host permission behind an opt-in?*

1. Add a **single hand-written** static rule (Phase 0 only — Phase 1 generates it) that
   strips `utm_source` for `urlFilter: "*"`, `resourceTypes: ["main_frame"]`; declare
   `declarativeNetRequest` + `optional_host_permissions: ["*://*/*"]`; ship the ruleset and
   request the permission from a popup button (`permissions.request`), then
   `updateEnabledRulesets`.
2. On device: navigate to a URL with `?utm_source=test`; confirm the address bar / loaded
   URL has it **removed**.
3. **Report before Phase 1:** (a) does iOS Safari honor `removeParams` on navigation? (b) is
   there a visible reload/redirect flash, and how bad? (c) does `optional_host_permissions`
   + runtime `permissions.request` + `updateEnabledRulesets` work on iOS? (d) is
   `removeParams` case-sensitive (our catalog is lowercased)? (e) does a host-scoped rule
   (`requestDomains`) work?

**STOP and report (do not improvise) if:** Safari ignores `removeParams`; the redirect
causes a user-hostile reload loop or flash; optional host permission can't be requested at
runtime; or rulesets can't be toggled. If DNR `removeParams` is fundamentally unavailable on
iOS Safari, **v2 as designed is infeasible** — do not fall back to the rejected
content-script/`webRequest` path without maintainer sign-off (it changes the whole privacy
calculus). Bring the numbers back.

## Phase 1 — build v2 (only after Phase 0 passes)

### Step 1 — `DNRRuleGenerator` (Core) + drift-guard test
Pure `nonisolated` enum: `TrackingParameterCatalog` → `[DNRRule]` → JSON `Data`. One global
`removeParams` rule (catalog-wide params, `resourceTypes:["main_frame"]`) + one host-scoped
rule per host that adds params (deterministic, sorted ids). Commit the emitted `rules.json`.
**Verify**: `cd LinkCleanKit && swift test` — a test regenerates and asserts the committed
`rules.json` matches (drift guard), plus shape assertions (valid ids, no empty removeParams).

### Step 2 — manifest
Add `declarativeNetRequest` to `permissions`; add `optional_host_permissions: ["*://*/*"]`;
add the `declarative_net_request` ruleset (`enabled: false`). Keep `activeTab` +
`nativeMessaging` (v1). **Never** add a non-optional `host_permissions` or
`declarativeNetRequestWithHostAccess`.
**Verify**: extension loads; `grep` shows the ruleset disabled by default.

### Step 3 — `background.js` (the relay/enabler)
On startup and on a message from the popup, read the stored opt-in flag (App Group via
native messaging, or extension storage) and `updateEnabledRulesets` accordingly. Handle the
permission grant/revoke.
**Verify**: toggling the flag enables/disables stripping (device).

### Step 4 — popup opt-in toggle
A "Auto-clean while browsing" toggle. Off → on triggers `permissions.request({origins:
["*://*/*"]})` (user gesture); on grant, persist the flag + enable the ruleset; on denial,
revert the toggle and explain. Show current status ("On — cleaning trackers as you browse").
**Verify**: device — enabling shows the iOS permission prompt; a `?utm_source=` URL strips.

### Step 5 — in-app Settings status + explainer
Extend the v1 Settings section: a row showing auto-strip status + a short, honest explainer
("LinkClean tells Safari to strip a known tracker list as you browse — it can't see your
pages"). Reuse the plan-004 Step 6 pattern. Free, no paywall.
**Verify**: `build-for-testing` → `EXIT 0`.

### Step 6 — analytics case + test
Add `case safariAutoStripToggled(enabled: Bool)` (`"Safari.AutoStrip.toggled"`,
`["enabled": …]`) + both switches + an `AnalyticsEventTests` assertion. Note the
no-per-strip-telemetry rationale in the doc-comment.
**Verify**: `cd LinkCleanKit && swift test` — new assertion passes.

### Step 7 — localization (en/ja/de)
The toggle, status, and explainer strings: popup strings in `_locales`; in-app strings in
`Localizable.xcstrings` (identifier keys + generated symbols). Match app vocab (ja クリーン,
de bereinigen). de is best-effort → native review.
**Verify**: switching device language flips the strings.

## Test plan

- **Fast lane (Core):** `DNRRuleGenerator` output (shape + the committed-`rules.json` drift
  guard) and the new `safariAutoStripToggled` case (signal name + params, no PII). The
  cleaning catalog itself is already covered by `URLCleanerTests` — do **not** re-test it.
- **Not unit-testable (manual device QA matrix — record in the status row):** enable
  auto-strip (see the iOS permission prompt); navigate to a `?utm_source=`/`?fbclid=` URL →
  stripped; navigate to a host-scoped case (e.g. YouTube `si`) → stripped; a trackerless URL
  → untouched, no reload; **disable** auto-strip → params survive again (no claw-back of the
  manual popup); confirm the **manual popup still works `activeTab`-only for a user who never
  opted in** (the privacy pin); confirm no URL is logged.
- Gate: `cd LinkCleanKit && swift test` (fast) + `build-for-testing` (app compile).

## Done criteria

ALL must hold:

- [ ] Phase 0 spike report exists (DNR `removeParams` strips on device + reload/UX note + permission-gating confirmed).
- [ ] `cd LinkCleanKit && swift test` → all pass, incl. the generator drift guard + `safariAutoStripToggled`.
- [ ] `xcodebuild build-for-testing -scheme LinkCleanTests …` → `EXIT 0`.
- [ ] `rules.json` is generated from the catalog (a drift-guard test proves it), **not** hand-written.
- [ ] `grep -i "declarativeNetRequestWithHostAccess" …/manifest.json` → **no matches** (transparent permission only).
- [ ] `grep -rin "utm_\|fbclid\|gclid" …/Resources/*.js` → **no matches** (no catalog/cleaning logic in JS; the param list lives only in generated `rules.json`).
- [ ] Host access is `optional_host_permissions`, requested at opt-in; the v1 manual popup is unchanged for non-opt-in users.
- [ ] No `ProGate` / `PaywallTrigger` / `PaywallView` files modified.
- [ ] Manual device QA matrix completed and recorded; `docs/plans/README.md` status row updated.

## STOP conditions

Stop and report (do not improvise) if:

- Phase 0 fails: iOS Safari ignores `removeParams`, the redirect is user-hostile, or the
  permission/ruleset gating doesn't work on iOS.
- You are tempted to clean URLs in JS (content script / `webRequest`) — the rejected,
  non-blind path. It changes the privacy calculus; needs maintainer sign-off.
- You are tempted to hand-write `rules.json` — it must be generated from the catalog.
- You are tempted to use `declarativeNetRequestWithHostAccess` or a non-optional
  `host_permissions` — transparent + optional only.
- Wiring anything requires a `ProGate` / paywall change — v2 is free.

## Maintenance notes

- **The reload question** is the real UX risk: a DNR `redirect` re-navigates to the stripped
  URL, which can flash/reload the page. Phase 0 measures it; if it's bad, consider scoping to
  fewer resource types or accepting it as the cost of ambient cleaning. Document the call.
- **Custom parameters in auto-strip** are deferred. v2 strips the default catalog only.
  Auto-stripping a user's *custom* params would need **dynamic** DNR rules
  (`updateDynamicRules`) generated from the App-Group custom set — a clean future "gate the
  addition" Pro lever if monetization ever wants one (it doesn't now).
- **Reviewer scrutiny:** (1) the host permission is optional + transparent + opt-in; (2) DNR
  is blind — no URL ever reaches the extension, no logging, no per-strip analytics; (3) the
  strip list is generated from the one Swift catalog, not a second JS list; (4) the manual
  popup's `activeTab`-only posture is preserved for users who never enable auto-strip.
