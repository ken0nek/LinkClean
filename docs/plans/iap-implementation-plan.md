# IAP Implementation — StoreKit 2

> **Status: implemented in 1.1** (2026-06-10). Built on **StoreKit 2**, not RevenueCat — a deliberate reversal of this plan's original choice; see "Why StoreKit 2, not RevenueCat" below.
> Scope: **how** IAP is built — engine, architecture, identity, measurement, testing.
> **Out of scope:** pricing, product lineup, free-tier limits, which features gate, paywall copy — that is `../strategy/iap-strategy.md`.
> Informed by the Whyzard retrospective (`../../../whyzard/...`) on identity hygiene, and modelled on Whyzard's own StoreKit 2 `EntitlementStore`.

## Why StoreKit 2, not RevenueCat

The first draft of this plan chose RevenueCat to be "the server we don't have." But the shipped scope is a **single non-consumable** with a **hand-rolled paywall**, **no subscriptions**, and **no grandfathering** — and at that scope RevenueCat's remaining value (its dashboard + the RevenueCatUI prebuilt paywall) doesn't apply:

- **A non-consumable needs no server.** The device is the entitlement store of record — `Transaction.currentEntitlements` syncs across the user's devices via their Apple Account, restore is `AppStore.sync()`, and the only out-of-band event (a refund) arrives on-device as a revocation through `Transaction.updates`. No App Store Server Notifications, no receipt-validation backend.
- **The paywall is custom SwiftUI**, so RevenueCatUI is unused (that was the "how easy is RevenueCat" experiment — discarded).
- **Revenue truth lives in App Store Connect** (Sales & Trends) plus the TelemetryDeck funnel (see Measurement). RevenueCat's dashboard isn't rebuilt — it's simply not needed.
- **On Apple's rails:** no third-party SDK, no external purchase-data processor (one fewer privacy disclosure — on-brand), smaller binary, no launch-time SDK init.

The `EntitlementsService` boundary keeps the engine swappable: if subscriptions / trials / remote A/B paywalls ever justify RevenueCat, it is one new service implementation, not a rewrite.

## Identity

StoreKit 2 + no server means **there is no billing identity to manage** — Apple owns it. The only app-managed identity is the **analytics ID** (Keychain UUID `analyticsInstallID`, TelemetryDeck `defaultUser`). The Whyzard-retro rule holds: never derive or cross-wire purchase data into the analytics ID, and never put any Apple/transaction identifier into TelemetryDeck. Purchase data and behavior data join at **dimension grain** (`tier` / `surface` default params), never at user grain. (`product.purchase(options: [.appAccountToken(…)])` is available for server correlation but unused — no server.)

## Architecture — where the code lives

StoreKit links to the **app target only**. Not LinkCleanKit, not the action extensions.

```
StoreKit
   │  Product.products · product.purchase · Transaction.updates / currentEntitlements · AppStore.sync
   ▼
StoreKitEntitlementsService            (app: Shared/Services/)  — maps Transaction → Entitlement, fail-closed
   ├──▶ EntitlementsModel (@Observable)   (app: UI gating state, stored property)
   └──▶ EntitlementStore.save(_:)         (kit: App Group snapshot)
              │
              ▼
   LinkCleanAction / LinkCleanMarkdownAction  — read-only, fail-closed (no SDK, no purchase UI)
```

**LinkCleanKit** (shared with extensions):

```swift
public nonisolated enum Entitlement: String, Sendable { case free, pro }

public nonisolated struct EntitlementStore: Sendable {     // App Group snapshot
    public func current() -> Entitlement                    // missing/unknown rawValue → .free (fail-closed)
    public func save(_ entitlement: Entitlement)
}
```

**App target** (`Shared/Services/`):

```swift
protocol EntitlementsService: Sendable {
    func currentEntitlement() -> Entitlement
    func entitlementStream() -> AsyncStream<Entitlement>     // wraps Transaction.updates
    func refreshEntitlement() async -> Entitlement           // re-resolve live + re-cache
    func proProduct() async throws -> ProProduct?            // maps StoreKit Product → DTO; no StoreKit type escapes
    func purchase() async throws -> PurchaseOutcome          // .completed / .cancelled / .pending
    func restorePurchases() async throws -> Entitlement
}
```

`StoreKitEntitlementsService` resolves `.pro` iff a **verified, non-revoked** `linkclean_pro_lifetime` transaction is in `Transaction.currentEntitlements`; unverified or revoked → `.free` (fail-closed). It persists every resolution to `EntitlementStore`, logs transitions, and finishes verified transactions. `ProProduct` / `PurchaseOutcome` are small `Sendable` DTOs so views and ViewModels never import StoreKit purchasing APIs.

`EntitlementsModel` — `@MainActor @Observable`, stored `private(set) var entitlement` updated from the stream (never a computed property over external state). Constructed once at the composition root, injected via `.environment`.

**Extensions:** read `EntitlementStore.current()` at launch — no SDK, no purchase UI. Staleness bounded by the next app launch (the snapshot rewrites on every resolution). With the current gating matrix the extensions need no checks; the snapshot stays dormant until some future extension-side Pro feature exists.

## Measurement architecture — one stack, two tools

The identity split forces the join to **dimension grain**, so neither tool's job is rebuilt in the other:

| Question | Source of truth |
|---|---|
| Activation, retention, core loop, app-vs-extension usage | TelemetryDeck |
| Behavior → paywall → purchase **funnel** | TelemetryDeck (analytics-ID grain) |
| Do Pro users behave differently? Which surface converts? | TelemetryDeck, sliced by `tier` / `surface` |
| Revenue, refunds, units, proceeds | **App Store Connect** (Sales & Trends) — never rebuilt in TelemetryDeck |

Connective mechanisms, no ID join:

1. **`tier` as a default parameter on every signal** (the one low-cardinality join dimension), wired via `TelemetryDeck.Config.defaultParameters` — a **closure** (`@Sendable () -> [String:String]`) reading `EntitlementStore`, so `tier` is evaluated live per signal (flips to `pro` the instant a purchase resolves). A per-target `surface` parameter (`app` / `action` / `markdownAction`) answers the share-sheet question the same way.
2. **The purchase funnel lives wholly in TelemetryDeck**, fired from the **custom paywall's view model**: `Paywall.Screen.shown(trigger)` → `Pro.Purchase.started` / `.completed` / `.failed(reason)` / `.restored(restored)`. Trigger is a fixed `PaywallTrigger` enum (never a URL or parameter name).
3. **Revenue analytics — dropped (2026-06-10).** The app does **not** call `TelemetryDeck.purchaseCompleted(transaction:)`; no transaction or amount reaches analytics. **App Store Connect is the sole source of revenue, refunds, units, and proceeds** (Sales & Trends). The `Pro.Purchase.*` funnel events above are count-only — behavior, not money. *(Why: TelemetryDeck revenue is "live, not correct" — no dedup — so it double-counts cross-device/reinstall restores.)*

Deliberately not done: any server-side forwarding (no server) and any user-grain bridge.

## Implementation (shipped 1.1)

- **Kit:** `Entitlement`, `EntitlementStore`, `SettingsKeys.currentEntitlement`, Swift Testing (round-trip, fail-closed on garbage).
- **App:** `StoreKitEntitlementsService`; `EntitlementsService` + `ProProduct` + `PurchaseOutcome`; `EntitlementsModel`; `ProGate` (free allowances — see strategy §6).
- **Custom paywall** (`Features/Paywall/PaywallView` + `PaywallViewModel`) + a reusable `.paywallSheet(trigger:entitlements:)` modifier. Gates T1–T4 attach where the strategy §9 trigger inventory says; each opens the sheet **on the gated tap**, never on screen entry.
- **DEBUG developer rows:** entitlement override (`Off` / `Free` / `Pro`) **persisted** and honored *first* by the service resolver (survives relaunch; the stream can't clobber it — Whyzard's pattern); paywall preview by trigger. No RC app-user-ID row (no RC).
- **StoreKit config** `LinkClean.storekit` (+ a `LinkClean (StoreKit)` scheme that references it) so purchase / cancel / restore / refund flow in the simulator without App Store Connect.

## Testing

1. **Unit (Swift Testing):** `EntitlementStore` round-trip + fail-closed; `ProGate` allowance; paywall funnel + outcomes through a mock `EntitlementsService`; History window split (`archive(from:isPro:now:)`). Domain mapping at the service boundary means tests never touch StoreKit types.
2. **StoreKit configuration file (simulator):** purchase, cancel, restore, **refund → revoked → drops out of `currentEntitlements`**, ask-to-buy → `.pending` surfaced as a calm "pending approval" alert. Test gating via the DEBUG override, not real purchases.
3. **Device + sandbox Apple Account:** full round trip; entitlement persists across relaunch-offline (resolved from the `EntitlementStore` cache); snapshot reaches both action extensions.

## Failure & edge behavior

- **Launch never blocks on StoreKit.** Gates read in-memory state or the App Group snapshot; the core clean-a-link flow never awaits the store.
- **No cache / unknown state → `.free`** (fail-closed), everywhere.
- **Refund / revocation:** Apple revokes the transaction; it drops from `currentEntitlements` (and replays via `Transaction.updates` with `revocationDate != nil`), so the next resolution returns `.free`. No webhook.
- **Reinstall / new device:** a fresh install resolves `.pro` automatically from `currentEntitlements` once the Apple Account syncs; **Restore** (`AppStore.sync()`) forces it. This is why Restore is prominent in Settings and on the paywall.

## App Store Connect setup

The one thing that requires the ASC UI (no RevenueCat dashboard, no fastlane IAP management): create the non-consumable, pricing, Family Sharing, the IAP review screenshot, and agreements. See **`../../apps/ios/LinkClean/docs/iap/app-store-connect-setup.md`** for the hand-off checklist.

## Deferred / not done

Grandfathering the 1.0 cohort (dropped 2026-06-10 — was the only feature that made `originalApplicationVersion`/RevenueCat convenient; re-addable later via `AppTransaction.shared.originalAppVersion` if 1.0 ships before 1.1). Subscriptions, trials, server-side verification, RevenueCat — out of scope by design.
