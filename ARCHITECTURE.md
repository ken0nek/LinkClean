# Architecture

LinkClean is a privacy-first link cleaner: an iOS app plus two share-sheet
action extensions (Clean URL, Copy as Markdown), sharing one local Swift package.
This document describes the system **as built** — after the redesign tracked in
`docs/ARCHITECTURE_PROPOSALS.md`.

## Platform & defaults

- iOS 26+ / iPadOS 26+, Swift 6.2, SwiftUI + SwiftData.
- Default actor isolation is **MainActor** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`); `nonisolated` opts out for background/pure work.
- Observation (`@Observable` + `@State`) — never `ObservableObject`/`@Published`/`@StateObject`.
- No Combine, no GCD (async/await, `Task`, actors).

## The package: four layered targets

`LinkCleanKit` is one SPM product with four targets. The dependency direction is
the architecture, **enforced by the compiler** — Core physically cannot reach
UIKit, SwiftData, or the analytics SDK.

```
LinkCleanCore        pure domain, nonisolated default, no deps/resources
  ↑                    URLCleaner, CleanOutcome (Telemetry/Display), CleanSession,
  │                    TrackingParameter* + ReferenceParameterCatalog, MarkdownFormatter,
  │                    OnboardingDemo, AnalyticsEvent + AnalyticsService, Entitlement,
  │                    ProGate, SettingsKeys, AppGroup, Log
LinkCleanData        → Core. MainActor default. Persistence.
  ↑                    SwiftData models + HistoryContainer, TrackingParameterStore,
  │                    SettingsStore, EntitlementStore, DebugEntitlementOverrideStore,
  │                    CleaningService, HistoryStore + HistoryRecorder, ReviewService,
  │                    LinkMetadataService
LinkCleanAnalytics   → Core (+Data). The only target linking TelemetryDeck.
  ↑                    TelemetryDeckAnalytics
LinkCleanExtensionUI → all. MainActor, UIKit. The extension layer + the only
                       string catalog in the package (toast strings).
                       ActionPipeline + ActionOutputStrategy (CleanLinkStrategy /
                       MarkdownLinkStrategy) + URLExtraction + ActionHostViewController
```

App and extension targets import only the layers they use. `Core`, `Data`, and
`Analytics` build and test on the Mac host; `ExtensionUI` links UIKit so it builds
for iOS only.

### Two-speed tests

- **Fast lane** (`swift test` in `LinkCleanKit/`, macOS, no simulator): `LinkCleanCoreTests` + `LinkCleanDataTests` — URL cleaning, catalogs, `CleanOutcome`, `CleanSession`, stores, review-gate rules, `ProGate`, `HistoryStore` (in-memory container). Runs in well under a second.
- **Sim lane** (`xcodebuild test -scheme LinkCleanKit` from `LinkCleanKit/`): `LinkCleanExtensionUITests` (UIKit — URL extraction + the action pipeline as values). The target's UIKit dependency is `.when(platforms: [.iOS])` and its sources are `#if canImport(UIKit)`, so on macOS it builds to an empty bundle.
- **App lane** (`xcodebuild test -scheme LinkCleanTests`): app-target ViewModel tests on the simulator.
- `LinkCleanTestSupport` (package target) holds the shared doubles: `SpyAnalytics`, `StubLinkMetadataService`, fixtures.

## Composition root

`AppDependencies` (app target) is the one place production dependencies are
constructed. `AppDependencies.live(container:)` — built once in `LinkCleanApp.init`
— wires every service, the `EntitlementsModel`, and the `HistoryStore`, and starts
the TelemetryDeck SDK (the SDK lifecycle lives next to the instance it configures;
screenshot builds suppress it here). `AppDependencies.preview()` returns offline
stubs for `#Preview`.

`LinkCleanApp` passes the dependencies to `ContentView`, which threads them to each
feature view; a view builds its ViewModel with `SomeViewModel(deps:)` (the
convenience inits live in `AppDependencies+ViewModels.swift`). **Views never
default-construct a production ViewModel.** ViewModel designated initializers keep
their parameters so tests pass explicit doubles.

`EntitlementsModel` is also injected into the SwiftUI environment
(`@Environment(EntitlementsModel.self)`) for views that gate UI on entitlement —
the same instance held in `AppDependencies`.

## MVVM

- One ViewModel per screen: `@MainActor @Observable final class`. Dependencies and tasks are `@ObservationIgnored`.
- ViewModels read external state (UserDefaults) via **stored properties refreshed at lifecycle boundaries** (`onAppear`, scene-phase) — `@Observable` doesn't track computed reads of UserDefaults.
- Views own `@State` (the ViewModel), `@FocusState`, `@Environment`, `@Query`, and presentation-only `@State` (alerts/sheets). No business logic in button closures — call a ViewModel intent.
- `@Query` reads stay in the View; **writes go through a store** (see History).
- Gate decisions are ViewModel intents returning a `GateResult` (`.allowed` / `.gated(PaywallRoute)`), not view-closure branches.

## The clean pipeline & the privacy boundary

A clean is one pass over the query items, producing a single `CleanOutcome`
(`LinkCleanCore`) whose privacy boundary is two nested types:

- **`Telemetry`** — the *only* shape `AnalyticsEvent` accepts. By construction it carries no raw query-key names: counts, catalog kind ids, public reference-catalog matches, and the site domain (the one disclosed URL-derived signal).
- **`Display`** — the raw removed/leftover key names for the on-device transparency UI. *Nothing* in `AnalyticsEvent` accepts a `Display`, so a raw name cannot reach analytics without a deliberate, reviewable conversion.

`CleaningService` (`LinkCleanData`) composes the user's rules
(`TrackingParameterStore.enabledParameters(forHost:)`) with `URLCleaner.outcome` —
one place, consumed by `HomeViewModel` **and both action extensions**.

`CleanSession` (`LinkCleanCore`) is the dedup ledger for a Home session: it owns
the five keys whose pairwise-different reset rules used to be emergent field
interactions, and exposes intent (`beginInput` / `setOutcome` / `noteCopy` /
`noteShare`) returning effects (`signalExport` / `recordHistory` / `countForReview`).
Every invariant is a table-driven unit test in the fast lane.

## History

`HistoryStore` (`LinkCleanData`, `@MainActor @Observable`) is the write/enrich
front door: `record` / `delete` / `clearAll`, plus `enrich` (it owns the metadata
fetch pool + concurrency cap). It writes through `container.mainContext` — the same
context `@Query` observes — with explicit `save()` and logged failures. Reads stay
`@Query` in `HistoryView`. There is no `setModelContext` dance.

`LinkMetadataService` (`LinkCleanData`) is shared by History enrichment and the
Markdown extension's title path — one `LPMetadataProvider` wrapper.

## Action extensions

The shared *sequence* is `ActionPipeline` (`LinkCleanExtensionUI`), parameterized
by an `ActionOutputStrategy`: extract a URL → clean via `CleaningService` →
`strategy.result(for:)` → write pasteboard → events → history → success signal →
return an `ActionPresentation` (toast kind + haptic + payload). `ActionHostViewController`
is the one thin UIKit host that renders the presentation. Each extension target is a
~3-line subclass naming a strategy (`CleanLinkStrategy` / `MarkdownLinkStrategy`);
a third extension would be a new strategy, not a fourth copy of the ritual. URL
extraction lives in `URLExtraction` (no view controller), testable as values.

## Entitlements (StoreKit 2, no RevenueCat, no server)

`StoreKitEntitlementsService` is the only StoreKit-touching type. `EntitlementsModel`
is the observable app-facing surface; it consumes the entitlement stream, keeps
grant-only restore semantics, and **emits the whole `Pro.Purchase.*` funnel from the
engine** (purchase + restore) so the funnel can't disagree across call sites.
ViewModels render outcomes only. `PaywallViewModel` depends on the
`EntitlementsProviding` protocol (not the concrete model), so it's testable with a
stub. Free-tier policy is `ProGate` (`LinkCleanCore`), beside `Entitlement`.

## Review prompt

`ReviewPromptFlow` (`@Observable`, app) owns the in-app star prompt end to end:
eligibility (via `ReviewService`), the once-per-session cap, the grace delay,
presentation, and the rated-high → system-prompt handoff. `HomeView` renders
`reviewFlow.isPresenting`; `HomeViewModel` only feeds it exports.

## Persistence contract (UserDefaults = the cross-process bus)

`UserDefaults` is the IPC bus between three processes (app + two extensions). All
keys live in `SettingsKeys` (the single registry) — never hard-coded. `SettingsStore`
is the typed facade; every **write** goes through it (or `TrackingParameterStore` /
`ReviewService` / the debug-override store), while views needing live reactivity may
read via `@AppStorage(SettingsKeys.…)` against the same constant/suite.

| Key | Suite | Writer | Reader |
|-----|-------|--------|--------|
| `autoPasteEnabled` | standard | SettingsStore (Settings) | HomeViewModel, SettingsViewModel |
| `hasCompletedOnboarding` | standard | OnboardingViewModel | ContentView (`@AppStorage`) |
| `saveHistoryEnabled` | App Group | SettingsStore (Settings) | Home/History/Settings, extensions |
| `lastActionExtensionRunAt` | App Group | ActionPipeline | ExtensionGuideViewModel |
| `trackingParametersDisabled/Enabled/Custom` | App Group | TrackingParameterStore | URLCleaner consumers (app + extensions) |
| `review*` (count / firstSuccessAt / lastPromptAt) | App Group | DefaultReviewService | DefaultReviewService |

History rows persist in a SwiftData store in the App Group container
(`HistoryContainer.makeShared()`), so the extensions and the app share one history.

## Analytics

The complete taxonomy is the `AnalyticsEvent` enum (`LinkCleanCore`) — call sites
cannot invent signal names or leak parameters. `AnalyticsService.capture(_:)` is the
only sink; `TelemetryDeckAnalytics` (`LinkCleanAnalytics`) is the only conformer that
touches the SDK. Numeric values are bucketed; the privacy tiers are documented per
case. See `docs/plans/analytics.md`.

## Localization (identifiers in the domain, strings at the edge)

Domain types ship **identifiers, not copy**: `TrackingParameterKind` carries an `id`
(`"utm"`); `ManageParametersView` maps it to a generated string-catalog symbol.
`Localizable.xcstrings` keys are identifiers compiled to type-safe symbols in the app
target. The **one** string catalog in the package is `LinkCleanExtensionUI`'s
(the action-extension toast strings), which the pipeline addresses semantically via
`ToastKind` and the host localizes. `LinkCleanCore`/`Data`/`Analytics` carry no
strings, no resources, no `defaultLocalization`. (See the CLAUDE.md localization note
for the `Bundle.module`/MainActor detail that keeps the catalog in ExtensionUI only.)
