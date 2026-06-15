# Plan 002: E4 — opt-in short-link expansion

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. If anything in "STOP
> conditions" occurs, stop and report — do not improvise. When done, update this
> plan's status row in `plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat 685aff6..HEAD -- LinkCleanKit/Sources/LinkCleanData/CleaningService.swift LinkCleanKit/Sources/LinkCleanData/SettingsStore.swift LinkCleanKit/Sources/LinkCleanCore/URLCleaner.swift`
> If any in-scope file changed since `685aff6`, compare the "Current state"
> excerpts against the live code before proceeding; on a mismatch, STOP.
>
> **Read `plans/SEED.md` first** — the eight standing LinkClean decisions. This
> plan records only the E4-specific answers and implementation; "SEED §N" points
> there for the shared rationale.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: HIGH (introduces the **first network call** into a privacy-absolute,
  offline-by-default engine — correctness and privacy framing both matter)
- **Depends on**: none
- **Category**: direction (feature)
- **Planned at**: commit `685aff6`, 2026-06-15

## Why this matters

Today the engine is 100% offline. `t.co` / `bit.ly`-class short links can't be
cleaned because the destination isn't in the URL — it's behind a redirect that
needs a network round-trip (that's exactly why E1 offline unwrapping *excludes*
them). E4 resolves a short link to its destination, then runs the normal
clean on that destination. It serves the researcher/poweruser persona and is the
one engine feature that touches the network — so it is **opt-in, off by default,
with honest copy** (the request reaches the shortener). Roadmap:
`docs/product/growth-roadmap.md:56` (E4, Pro, opt-in regardless of tier) and the
free/Pro reasoning at `:59`.

> **Strategy caveat (read before building):** the free market-leader competitor
> ships short-link expansion *for free* (`docs/strategy/competitor-clean-links.md:112`),
> so E4 is a **weak Pro paywall** and a poor *headline*. Build it as an opt-in
> utility (Pro-to-enable per the roadmap), not as a marketing centerpiece. If the
> intent is a flagship Pro beat, the stronger pick is ai-C / history-AI, not E4.

## Current state

Files and roles:

- `LinkCleanKit/Sources/LinkCleanData/CleaningService.swift` — `DefaultCleaningService`,
  the **one async seam** that every surface (app + both action extensions + App
  Intents) cleans through. E4 hooks in here, before the offline unwrap.
- `LinkCleanKit/Sources/LinkCleanData/SettingsStore.swift` — the toggle store;
  `removeTextFragmentsEnabled` is the **exemplar toggle** to copy.
- `LinkCleanKit/Sources/LinkCleanCore/URLCleaner.swift` — pure offline engine
  (`unwrap`, `clean`, `isWebURL`, `firstWebURL`). The shortener **host set** (pure
  data) goes here; the **network resolver** does NOT (Core has no network).
- `SettingsKeys` (find it: `grep -rn "removeTextFragmentsEnabled" LinkCleanKit/Sources`)
  — add the new key beside the existing ones.

The seam (`CleaningService.swift:60-70`, abbreviated):

```swift
public nonisolated struct DefaultCleaningService: CleaningService {
    private let store: TrackingParameterStore
    private let settings: SettingsStore
    // ...
    public func clean(_ input: String, removingAlso extraParameters: Set<String>) async throws -> CleanOutcome? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, URLCleaner.isValidURL(trimmed) else { return nil }
        // Peel known redirect wrappers first (OFFLINE), then resolve rules
        // against the destination's host.
        let unwrap = URLCleaner.unwrap(trimmed)
        let enabled = store.enabledParameters(forHost: URLCleaner.ruleHost(of: unwrap.destination))
        // ... URLCleaner.outcome(for: unwrap.destination, removing: …, wrappers: unwrap.wrappers)
    }
}
```

The exemplar toggle (`SettingsStore.swift:53-56`) — note App-Group suite so the
extensions/intents read the same value, and the default-when-unset:

```swift
public var removeTextFragmentsEnabled: Bool {
    get { appGroup?.object(forKey: SettingsKeys.removeTextFragmentsEnabled) as? Bool ?? true }
    nonmutating set { appGroup?.set(newValue, forKey: SettingsKeys.removeTextFragmentsEnabled) }
}
```

## Foundation Models — N/A

E4 uses no AI (SEED §4 doesn't apply). The analogous budget concern is **network
latency in the short-lived share extension** — see "Surfaces" below.

## Surfaces — app + App Intents (v1); extension deferred for latency

Because `DefaultCleaningService` is the shared seam, putting E4 there makes it
*reachable* from every surface. But a network round-trip has different budgets per
surface, so wire it deliberately via **where the resolver is injected**:

| Surface | This plan? | Why |
|---|---|---|
| **Main app (Home)** | ✅ Yes | The clean is already async (`cleanTask`); a 3–5 s network resolve with a spinner is acceptable. |
| **App Intents** (`CleanLinkIntent` / `CleanClipboardIntent`) | ✅ Yes | Run nonisolated, off the main thread; tolerate the await. |
| **Action / share extension** (`ActionPipeline` / strategies) | ❌ **Deferred** | Short-lived process with a tight time budget already spent on `LPMetadataProvider`; adding a redirect round-trip risks the share completing slowly or being killed. Inject the resolver here only after measuring the budget (mirror ai-C's extension caution). |

Mechanism: E4 reads the App-Group `expandShortLinksEnabled` toggle (visible to all
surfaces) **and** requires a `ShortLinkResolving` resolver to be injected into
`DefaultCleaningService`. v1 injects the resolver in the app + intents composition
only; the extension's `DefaultCleaningService` keeps a `nil` resolver, so even with
the toggle on it skips expansion there. So the answer to "only app / only extension
/ both": **app + App Intents in v1; the extension is wired later behind a latency check.**

## Free vs Pro

E4 is **Pro-to-enable** and **opt-in (off by default) regardless of tier**, applying
iap §6 rule 3 — *gate addition, not operation* (`docs/product/growth-roadmap.md:56,59`).

| Capability | Free | Pro |
|---|---|---|
| Offline clean + E1 offline unwrap | ✅ | ✅ |
| Short links (`t.co`/`bit.ly`) | pass through unexpanded | **expandable** once the toggle is on |
| The expansion toggle | ❌ tapping it raises the paywall | ✅ can enable (defaults **off**) |

- **Stays free:** the *operation* — every offline clean, including E1 unwrapping — is
  unchanged; short links simply pass through uncleaned for free users, exactly as today.
- **Pro unlocks:** the *ability to turn on* network expansion — an *addition* (a new,
  network-touching capability), not the core operation.
- **Mechanism (Step 4):** the Settings toggle is **Pro-gated to enable** — a free user
  tapping it raises the paywall (match the custom-rules gate). Once a Pro user enables
  it, it persists and the clean honors it — **never clawed back**, and *free to run* even
  if entitlement later lapses (the gate is on enabling, not running).
- **Opt-in regardless of tier:** even for Pro users the toggle defaults **off** — this is
  the app's only network egress, so the user must choose it explicitly.
- **Affected areas (SEED §3 + §6):** Step 4 adds a new `AnalyticsEvent.PaywallTrigger`
  case + a `Settings.*.toggled` event, but **no headline paywall benefit row** — E4 is a
  weak/utility gate (see caveat), so it stays a Settings toggle, not a paywall pitch.
- **⚠️ Weak-paywall caveat (decide before shipping):** the free competitor ships
  expansion free (`docs/strategy/competitor-clean-links.md:112-114,133`), so charging for
  it is a *weak* gate. The roadmap keeps E4 Pro and this plan honors that — but if it
  doesn't convert, making E4 **free** (still opt-in, for the network reason) is a clean
  reversal: drop the paywall trigger on the toggle (Step 4), leave everything else intact.

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Kit fast lane | `cd LinkCleanKit && swift test` | all suites pass (was 266) + new resolver/catalog tests |
| App + extension compile | `xcodebuild build-for-testing -project LinkClean.xcodeproj -scheme LinkCleanTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -quiet` | `EXIT: 0` |

## Scope

**In scope:**
- `LinkCleanKit/Sources/LinkCleanCore/ShortenerCatalog.swift` (create — pure host set + `isShortener(host:)`)
- `LinkCleanKit/Sources/LinkCleanData/ShortLinkResolver.swift` (create — `protocol ShortLinkResolving: Sendable` + `URLSessionShortLinkResolver` + a disabled/`nil` default)
- `LinkCleanKit/Sources/LinkCleanData/CleaningService.swift` (inject an optional resolver; resolve before `unwrap` when toggle on + host is a shortener)
- `LinkCleanKit/Sources/LinkCleanData/SettingsStore.swift` + `SettingsKeys` (add `expandShortLinksEnabled`, App-Group, **default `false`**)
- App Settings UI: the toggle row (Pro-gated to *enable*) — find the existing toggle rows (`grep -rn "removeTextFragments\|Toggle" LinkClean/Features/Settings`) and match the pattern, including the Pro gate used by custom rules.
- App + Intents composition: inject `URLSessionShortLinkResolver()` into their `DefaultCleaningService`.
- Tests: `LinkCleanKit/Tests/LinkCleanCoreTests/ShortenerCatalogTests.swift`, `LinkCleanKit/Tests/LinkCleanDataTests/ShortLinkResolverTests.swift` (+ a `CleaningService` test with a stub resolver).

**Out of scope (do NOT touch):**
- The extension targets' `DefaultCleaningService` construction — leave the resolver `nil` there (latency-deferred).
- `URLCleaner.unwrap` (offline E1) — E4 runs *before* it, doesn't change it.
- Making the network call anywhere in `LinkCleanCore` — Core stays offline/pure.

## Steps

### Step 1: `ShortenerCatalog` (Core, pure data)

Create `ShortenerCatalog` in `LinkCleanCore` with a `Set<String>` of known shortener
hosts (`t.co`, `bit.ly`, `tinyurl.com`, `goo.gl`, `ow.ly`, `is.gd`, `buff.ly`,
`t.ly`, `rebrand.ly`, `cutt.ly`, `shorturl.at`, `lnkd.in` — verify none overlap the
E1 *offline* wrapper catalog; if a host is already offline-unwrapped, it must not be
in this set) and `static func isShortener(host: String?) -> Bool` (lowercased, `www.`-stripped).

**Verify**: `cd LinkCleanKit && swift test` → passes (add the test from "Test plan").

### Step 2: `ShortLinkResolver` (Data, network)

Create `protocol ShortLinkResolving: Sendable { func resolve(_ url: URL) async -> URL? }`
and `struct URLSessionShortLinkResolver: ShortLinkResolving`. Implementation:
- A `URLRequest` (HEAD; fall back to GET if a host rejects HEAD) with a short timeout
  (`timeoutIntervalForRequest` ≈ 5 s) on a `URLSession` that **follows redirects**
  (default behavior) but cap the chain (use a delegate or a manual loop with a max of
  ~10 hops to avoid loops).
- Return the **final** resolved URL only if it `URLCleaner.isWebURL(...)`; otherwise `nil`.
- Fail soft: any error / timeout / non-web result → `nil` (caller cleans the original).
- No logging of the URL itself (privacy); `Log.app.debug` may note "resolve failed"
  without the link.

**Verify**: `build-for-testing` → `EXIT: 0`.

### Step 3: Wire into `DefaultCleaningService` (toggle-gated, before unwrap)

- Add `private let resolver: ShortLinkResolving?` (default `nil`) to `DefaultCleaningService.init`.
- In `clean`, after the `guard` and before `URLCleaner.unwrap`:

```swift
var working = trimmed
if settings.expandShortLinksEnabled,
   let resolver,
   let url = URL(string: trimmed),
   ShortenerCatalog.isShortener(host: url.host),
   let expanded = await resolver.resolve(url) {
    working = expanded.absoluteString
}
let unwrap = URLCleaner.unwrap(working)   // then everything proceeds on `working`
```

(Replace the later `trimmed` uses in `unwrap`/host resolution with `working`.)

**Verify**: `cd LinkCleanKit && swift test` → passes (add the stub-resolver CleaningService test).

### Step 4: `expandShortLinksEnabled` toggle + Settings row

- Add `expandShortLinksEnabled` to `SettingsStore` (App-Group suite, **default `false`**)
  and its `SettingsKeys` constant, mirroring `removeTextFragmentsEnabled`.
- Add a Settings toggle row with **honest footer copy** (e.g. "Expanding a short link
  contacts the link's service to find its destination. Off by default; nothing is sent
  anywhere else."). **Enabling** it is Pro-gated — match the gate the custom-rules row
  uses (Grep `paywallTrigger`/`ProGate` in `LinkClean/Features/Settings`). Add a new
  `AnalyticsEvent.PaywallTrigger` case if the gate needs one, and a
  `Settings.*.toggled` analytics event mirroring `settingsTextFragmentsToggled`
  (run the analytics-audit pattern: extend `AnalyticsEvent` + both switches + a test).

**Verify**: `build-for-testing` → `EXIT: 0`.

### Step 5: Inject the resolver in app + intents (NOT the extension)

Grep `DefaultCleaningService(` to find construction sites. In the **app** and **App
Intents** sites, pass `resolver: URLSessionShortLinkResolver()`. Leave the **extension**
site's resolver unset (`nil`). If a site is shared/ambiguous, STOP and report.

**Verify**: `grep -rn "URLSessionShortLinkResolver(" LinkCleanKit/Sources/LinkCleanExtensionUI` → **no matches**; `build-for-testing` → `EXIT: 0`.

## Test plan

- `ShortenerCatalogTests` (model after `LinkCleanKit/Tests/LinkCleanCoreTests/URLCleanerTests.swift`):
  `isShortener` true for `bit.ly`/`t.co`/`www.bit.ly`, false for `example.com`; assert
  **no overlap** with the offline E1 wrapper hosts.
- `ShortLinkResolverTests` + a `DefaultCleaningService` test using a **stub
  `ShortLinkResolving`** (no real network): toggle **off** → original URL cleaned, resolver
  never called; toggle **on** + shortener host → resolver's destination is what gets
  cleaned; resolver returns `nil` → falls back to cleaning the original (never throws).
  Model after `LinkCleanKit/Tests/LinkCleanDataTests/DefaultCleaningServiceTests.swift`.
- Do **not** write a test that hits the real network.

## Done criteria

ALL must hold:

- [ ] `cd LinkCleanKit && swift test` → all suites pass, incl. new catalog/resolver/CleaningService tests.
- [ ] `xcodebuild build-for-testing … -scheme LinkCleanTests …` → `EXIT: 0`.
- [ ] Toggle defaults to **`false`** (assert in a `SettingsStore` test).
- [ ] `grep -rn "URLSession\|\.resolve(" LinkCleanKit/Sources/LinkCleanCore` → no network in Core.
- [ ] Resolver is **not** injected into any extension `DefaultCleaningService`.
- [ ] No files outside the in-scope list are modified (`git status`).
- [ ] `plans/README.md` status row for 002 updated.

## STOP conditions

Stop and report (do not improvise) if:

- The `CleaningService.swift` / `SettingsStore.swift` excerpts don't match the live
  code (drift since `685aff6`).
- `DefaultCleaningService` is constructed in a place shared between the app and an
  extension such that you can't inject the resolver for app/intents without also
  enabling it in the extension.
- The Pro gate for Settings toggles can't be matched from an existing example
  (don't invent a gating mechanism).
- A shortener host you'd add already exists in the offline E1 wrapper catalog
  (double-resolution risk).

## Maintenance notes

- **Extension surface is deferred on purpose.** Wiring the resolver into the share
  extension needs a measured share-time budget check (the extension can be killed if
  it runs long); do it as a follow-up with a timeout tuned for the extension, not the app.
- **Privacy framing is load-bearing.** This is the only network egress in a
  privacy-absolute app: keep it off by default, keep the toggle copy honest, never log
  the link, and never send it anywhere but the shortener itself. A reviewer should
  confirm all four.
- **Determinism note (`ai-features.md` §3):** the core clean stays deterministic and
  offline by default; E4 is additive and opt-in, so it doesn't violate that rule —
  keep it that way (no implicit/auto enabling).
- If `URLCleaner.unwrap` later learns to follow *online* wrappers, reconcile the host
  sets so a link isn't both expanded (E4) and unwrapped (E1).
