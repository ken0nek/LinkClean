# IAP Implementation Plan — RevenueCat

> **Status: planned** — as of 2026-06-05.
> Scope: **how** IAP is built — identity, architecture, RevenueCat integration, testing, ship sequence.
> **Out of scope:** pricing, product lineup, free-tier limits, which features gate, paywall design — that is the separate "IAP strategy" item in `docs/TODO.md` (1.1.0). This plan deliberately works without those answers; nothing here changes when they land.
> Informed by the Whyzard retrospective (`../whyzard/docs/decisions/Whyzard_Engineering_Retrospective.md`), §4 (identity migration) and checklist #6 (two identities from day one).

## Why RevenueCat

- LinkClean has **no backend**. RevenueCat is the entitlement store of record, receipt validator, and revenue dashboard — the entire server side Whyzard had to hand-roll (ASSN webhooks, KV namespaces, jsrsasign workarounds).
- Deliberate experiment: Whyzard built; LinkClean buys. The retro's condition applies in reverse: **buying first is fine only while building later remains a swap, not a rewrite.** All RevenueCat types stay behind one service protocol (`EntitlementsService`); views and ViewModels never import RevenueCat. Dropping to raw StoreKit 2 later = one new service implementation.
- SDK: `purchases-ios` 5.x (`RevenueCat` + `RevenueCatUI` products), StoreKit 2 mode.

## Decision 1 — Two identities, locked before 1.0 ships

This is the only part of this plan that is **blocking for 1.0** (the TelemetryDeck TODO item). The retro's window: *"migrate at zero state — the window closes at the first durable record."* For LinkClean the first durable record is the 1.0 launch cohort's first analytics event.

| Identity | Value | Owner | Consumers |
|---|---|---|---|
| **Analytics ID** | Keychain UUID, named `analyticsInstallID` | Analytics facade (1.0 work) | TelemetryDeck `defaultUser` — nothing else |
| **Billing ID** | RevenueCat **anonymous app user ID** (`$RCAnonymousID:...`) | RevenueCat SDK | RevenueCat only |

Hard rules (the Whyzard trap was one id doing 3–5 jobs):

1. **Never** call `Purchases.configure(withAPIKey:appUserID:)` or `Purchases.logIn()` with the analytics ID — or anything derived from it.
2. **Never** feed RevenueCat's app user ID into TelemetryDeck (`defaultUser`, signal payloads, anywhere).
3. The Keychain UUID lives **inside the analytics facade**, private, billing-blind by name. If the action extensions ever send analytics, share the *analytics* ID via App Group — never the billing ID.
4. Consequence, accepted consciously (retro §3 "four data islands"): RevenueCat revenue data and TelemetryDeck behavior data **never join at user grain**. They join at *dimension* grain instead — see "Measurement architecture" below, which is where the two tools earn their keep together. If a concrete KPI question ever requires a user-grain join, the only allowed bridge is one-directional — analytics ID pushed into a RevenueCat subscriber attribute — never the reverse, and only after a privacy-policy review. Default: no bridge.

## Decision 2 — Anonymous billing ID, not UUIDv5(appTransactionID)

The retro recommends shaping the billing id as UUIDv5 over `appTransactionID`. That mechanism served Whyzard's **own** KV entitlement store, which needed a deterministic cross-device key. We keep the retro's *principle* (analytics ≠ billing) but not its *mechanism*:

| | UUIDv5(appTransactionID) | RC anonymous ID (chosen) |
|---|---|---|
| Cross-device / reinstall | Deterministic key | Restore Purchases → RC merges anonymous IDs (default transfer behavior) |
| Launch cost | `AppTransaction.shared` is `async throws`, can hit network → bootstrap + cache + fallback machinery (retro §4's pain) | Zero — synchronous configure |
| OS floor | `appTransactionID` is iOS 18.4+; was a gap at the original 18.0 deployment target (moot now that the floor is 26.0) | None |
| What it buys without our own server | Nothing — RC is the entitlement store either way | The RC-recommended mode for account-less apps |

Escape hatches if circumstances change (recorded so this isn't re-litigated):

- **Accounts later:** `Purchases.logIn(customID)` aliases the anonymous history into the identified user. Decision deferred, not foreclosed.
- **Server later:** RC webhooks key on the RC app user ID; no client migration needed.

## Decision 3 — Where the code lives

RevenueCat SDK links to the **app target only**. Not LinkCleanKit, not the action extensions — extensions must never initialize a purchases SDK (memory limits, no purchase UI there anyway), and the kit stays dependency-free.

```
StoreKit / RC backend
        │
        ▼
Purchases.shared.customerInfoStream            (app target)
        │
        ▼
RevenueCatEntitlementsService                  (app: Shared/Services/)
        │  maps CustomerInfo → Entitlement, logs transitions
        ├──▶ EntitlementsModel (@Observable)   (app: UI state, stored property)
        └──▶ EntitlementStore.save(_:)         (kit: App Group snapshot)
                    │
                    ▼
        LinkCleanAction / LinkCleanMarkdownAction read-only, fail-closed
```

**LinkCleanKit** (domain, shared with extensions — modeled on `TrackingParameterStore`):

```swift
public nonisolated enum Entitlement: String, Sendable {
    case free
    case pro            // placeholder id until the strategy doc lands
}

public nonisolated struct EntitlementStore: Sendable {
    public init(suiteName: String? = AppGroup.identifier)
    public func current() -> Entitlement     // missing/unknown rawValue → .free (fail-closed)
    public func save(_ entitlement: Entitlement)
}
```

Key string goes in `SettingsKeys`. Fail direction is **closed** (`.free`), same reasoning as Whyzard's `resolveTier`: a corrupt record must never read as "unlimited". Decoding via `Entitlement(rawValue:) ?? .free` keeps future tier additions decode-safe for stale extension binaries.

**App target** (`Shared/Services/`, matching `URLCleaningService` shape):

```swift
protocol EntitlementsService: Sendable {
    func currentEntitlement() -> Entitlement
    func entitlementStream() -> AsyncStream<Entitlement>   // wraps customerInfoStream
    func restorePurchases() async throws -> Entitlement
}
```

No `purchase()` method initially — RevenueCatUI's paywall drives the purchase itself (that's the experiment). If we ever hand-roll a paywall, `purchase(package:)` gets added then.

`EntitlementsModel` is `@MainActor @Observable final class` with a **stored** `private(set) var entitlement: Entitlement = .free` updated from the stream — never a computed property over external state (see `ARCHITECTURE.md` / the `@Observable` + UserDefaults rule). Constructed once at the composition root, injected where gating needs it.

**Extensions:** read `EntitlementStore.current()` at launch. No purchase UI, no SDK. Staleness is bounded by the next app launch (snapshot rewrites on every `CustomerInfo` update); a lapsed subscription lingering as pro in the extension until then is accepted.

## Measurement architecture — one stack, two tools

The identity split (Decision 1) is not a wall between the tools — it forces the join to happen at **dimension grain** instead of ID grain. Division of labor, so neither tool's job gets rebuilt in the other:

| Question | Source of truth |
|---|---|
| Activation, retention, core loop (links cleaned), app-vs-extension usage | TelemetryDeck |
| Behavior → paywall → purchase **funnel** | TelemetryDeck (funnel events, analytics-ID grain) |
| Do pro users behave differently? Which surface converts? | TelemetryDeck, sliced by `tier` / `surface` |
| Revenue, MRR, conversion *rates*, churn, refunds | RevenueCat charts — never rebuilt in TelemetryDeck |
| Paywall impressions + A/B experiments (later) | RevenueCat |
| Individual customer lookup (support, entitlement debugging) | RevenueCat customer dashboard |

Three connective mechanisms, none requiring an ID join:

1. **`tier` as a default parameter on every signal** — the retro's "one deliberate low-cardinality join dimension" (Whyzard used `model`; LinkClean uses `tier`). Wired via `TelemetryDeck.Config.defaultParameters`, reading `EntitlementStore` — the same kit snapshot that gates the extensions also enriches analytics in **every** target. Ships in 1.0 as the literal `"free"` so the launch cohort's metrics stay schema-compatible once tiers exist; 1.1 swaps the literal for the snapshot read. A per-target `surface` parameter (`app` / `action` / `markdownAction`) answers the share-sheet question the same way.
2. **The purchase funnel lives wholly in TelemetryDeck**, fired client-side from RevenueCatUI's paywall callbacks (`onPurchaseStarted` / `onPurchaseCompleted` / `onPurchaseCancelled` / `onPurchaseFailure` / `onRestoreCompleted`). Keyed on the analytics ID like every other signal, so *"cleaned 3 links via the extension → saw paywall → bought"* is one TelemetryDeck funnel. RevenueCat independently tracks paywall impressions — it stays the source of truth for conversion *rates*; the TelemetryDeck events exist for *behavioral context*, and the two are expected not to reconcile exactly.
3. **TelemetryDeck's Purchases preset, fed at RevenueCat's completion callback:** `TelemetryDeck.purchaseCompleted(transaction:)` with the underlying SK2 transaction (`storeTransaction.sk2Transaction`) auto-sends USD-normalized revenue — revenue cohorted against behavior inside TelemetryDeck. Directional only (client-side, blind to refunds and off-device renewals); RevenueCat remains authoritative for money.

Deliberately not done: RC→TelemetryDeck server-side forwarding (RC has no TelemetryDeck integration; webhooks need a server we don't have), and any user-grain bridge (Decision 1, rule 4).

## Implementation phases

### Phase 0 — in 1.0, now (cheap today, a migration later)

- [ ] **[blocking]** Bake Decision 1 into the 1.0 TelemetryDeck work: facade-private Keychain UUID named `analyticsInstallID`, with a comment stating the never-cross-with-billing rule.
- [ ] **[cheap, recommended]** Reserve the purchase-funnel event names in the analytics facade's closed enum, shipped unfired (retro §3: the funnel was instrumented *ahead of* the IAP feature): `paywallShown(trigger)`, `purchaseStarted(productID)`, `purchaseCompleted(productID)`, `purchaseFailed(reason)` (closed enum: `cancelled`/`pending`/`storeError`), `restoreCompleted(restored)`. No PII, no IDs of either kind in payloads.
- [ ] **[cheap, recommended]** Default parameters from signal #1: `tier` (literal `"free"` until 1.1) and per-target `surface` — see "Measurement architecture". Neither can be backfilled; the pre-IAP cohort is measured exactly once. If the action extensions send signals, they share the *analytics* ID via App Group (Decision 1, rule 3) so an app+extension user counts as one user.
- Nothing else moves to 1.0. `EntitlementStore` ships with 1.1 — extensions fail closed to `.free` regardless.

### Phase A — accounts & dashboards (handoff: Ken)

1. **App Store Connect:** Paid Apps agreement + banking/tax. *Longest lead time — start first; everything else can proceed in parallel.*
2. **App Store Connect:** create IAP products — **blocked by the strategy doc** (lineup/pricing). Only the product IDs matter to this plan.
3. **RevenueCat dashboard:** create project + iOS app (bundle ID of the LinkClean app target); upload the In-App Purchase Key (.p8) and App Store Connect API key; create entitlement `pro` (placeholder), a `default` offering, attach products; build the paywall in the dashboard editor (copy/layout stay server-editable — no client release for paywall tweaks). Copy the **public** Apple SDK key.
4. **Xcode GUI** (per CLAUDE.md handoff rule): add SPM dependency `https://github.com/RevenueCat/purchases-ios-spm.git` (Up to Next Major from 5.x), products **RevenueCat** and **RevenueCatUI**, **LinkClean app target only**. No entitlement/capability change needed for StoreKit on iOS.
5. **Xcode GUI:** once products exist in ASC, create a StoreKit Configuration file (synced from App Store Connect) and set it on the LinkClean scheme's Run options.

### Phase B — code (Claude)

1. Kit: `Entitlement`, `EntitlementStore`, `SettingsKeys` entry, Swift Testing tests (round-trip, fail-closed on garbage).
2. Configure at the composition root (`LinkCleanApp.init()`):

```swift
#if DEBUG
Purchases.logLevel = .debug
#endif
if !arguments.contains("-uiTesting") {        // keep UI tests deterministic & offline
    Purchases.configure(
        with: Configuration.Builder(withAPIKey: RevenueCatConfig.apiKey)  // public/publishable key — safe in source
            .with(storeKitVersion: .storeKit2)
            .build()
    )
    // No appUserID — anonymous by design (Decision 1). Never pass one.
}
```

3. `RevenueCatEntitlementsService`: `for await` over `customerInfoStream`, map `customerInfo.entitlements["pro"]?.isActive` → `Entitlement` **at the service boundary** (RC types never escape), persist via `EntitlementStore`, log transitions with `Log.logger`.
4. Paywall surface: `.presentPaywallIfNeeded(requiredEntitlementIdentifier: "pro")` / `PaywallView` from RevenueCatUI — this is the "how easy is RevenueCat" experiment. Trigger points are a strategy decision; the modifier attaches wherever that lands.
5. Restore path in Settings (App Review requirement): try RevenueCatUI's `CustomerCenterView` first (manage + restore + refund requests in one drop-in); fall back to a plain "Restore Purchases" row calling the service if it doesn't fit.
6. Localization: paywall copy lives in the RC dashboard (not `Localizable.xcstrings`). App-side strings (Settings rows, pending-purchase toast) follow the identifier-key + generated-symbol pattern; any kit strings use the explicit-key pattern (kit catalog must stay free of `manual` entries).
7. DEBUG-only developer rows in Settings (retro #17, scoped down — the trigger ships with the mechanism): paywall preview, entitlement override (`off`/`free`/`pro`, read by `EntitlementsModel` in DEBUG only), current RC app user ID display+copy (for sandbox dashboard lookups). All compiled out of Release.
8. Measurement wiring (see "Measurement architecture"): attach the Phase-0 funnel events to RevenueCatUI's paywall callbacks; call `TelemetryDeck.purchaseCompleted(transaction:)` from `onPurchaseCompleted` (use the callback variant that provides the `StoreTransaction`; pass its `sk2Transaction`); switch the `tier` default parameter from the 1.0 literal to the `EntitlementStore` read.

### Phase C — testing

1. **Unit (Swift Testing, `LinkCleanTests` / kit tests):** `EntitlementStore` round-trip + fail-closed; gating reads through a mock `EntitlementsService` (domain mapping at the service boundary means tests never touch RC types).
2. **StoreKit Configuration file (simulator):** purchase, cancel, restore, refund, ask-to-buy → `ErrorCode.paymentPendingError` surfaced as a "pending approval" toast, not an error. Caveats: products must *also* exist in the RC dashboard or backend validation fails; known iOS 18.4-sim product-loading quirk — RC's docs recommend config-file testing as the workaround.
3. **Device + sandbox Apple Account:** full round trip against the real RC backend — entitlement appears in the RC customer dashboard, snapshot reaches **both** action extensions, relaunch-offline still resolves pro from cache.

### Phase D — release checklist (1.1)

- [ ] Restore Purchases reachable without purchasing (App Review)
- [ ] Paywall shows price, term, Terms of Use (EULA) + Privacy Policy links (RC templates have slots; links must resolve)
- [ ] App Privacy questionnaire updated: add "Purchases" data type (RC SDK ships its own privacy manifest, but the ASC answers are ours)
- [ ] Funnel events + Purchases preset verified in TelemetryDeck against a sandbox purchase (DEBUG builds send test-mode signals — flip the Test Mode toggle in the TelemetryDeck dashboard)
- [ ] RC dashboard: offering marked current, paywall published
- [ ] Sequencing of any feature walls relative to the purchase path = strategy doc; the mechanism supports shipping purchases before any wall exists (retro: observe-first, enforce-later)

## Failure & edge behavior

- **Launch never blocks on RevenueCat.** Configure is fire-and-forget; gates read in-memory state or the App Group snapshot. The core clean-a-link flow never awaits a network call.
- **No cache / unknown state → `.free`** (fail-closed), everywhere — app and extensions.
- **RC outage:** SDK serves cached `CustomerInfo`; StoreKit 2 purchases still complete and sync later.
- **Refund/expiry:** reflected on next `CustomerInfo` refresh; extension staleness bounded by next app launch (accepted above).
- **Reinstall / new device:** fresh anonymous ID sees `.free` until the user taps Restore — RC then merges the anonymous IDs (default transfer behavior). This is why Restore must be prominent, not buried.

## Out of scope / deferred (decide in the strategy doc)

Product mix (subscription vs lifetime), pricing, trials/intro offers, gated-feature list and free-tier limits, grandfathering the 1.0 cohort, paywall triggers and design, Family Sharing, RC webhooks (needs a server), win-back offers.
