# Architecture Proposals

A from-scratch redesign assessment of LinkClean, written against the codebase as of June 2026 (post-IAP, branch `feature/iap`). Backward compatibility is explicitly out of scope: proposals assume freedom to break persisted formats, UserDefaults keys, and internal APIs. The only constraint honored is the implementation order at the end — every step must leave the project compiling, tests green, and shippable.

---

## What stays (deliberately not proposed)

The foundation is sound, and several deliberate choices should survive any redesign:

- **MVVM with `@Observable` + `@State`.** The ViewModels carry genuinely testable orchestration (dedup rules, analytics emission, gating) and the test suite proves the seams work. No move to TCA, no move to "MV"/view-only state.
- **Typed analytics (`AnalyticsEvent` enum).** Call sites cannot invent signal names or leak parameters; the privacy tiers are documented per case. This is better than most production apps. Proposals below *strengthen* it (P2), never replace it.
- **Raw StoreKit 2, no RevenueCat, no server.** Right call for a single non-consumable with a privacy-first brand.
- **SwiftData + `@Query` in views, writes elsewhere.** Keep.
- **No Combine, no GCD, MainActor-default isolation.** Keep.
- **No router/coordinator layer.** Three tabs and a handful of sheets do not need one.
- **Hand-rolled paywall, hard-coded review-gate cadence, bundled parameter catalogs.** All appropriately boring.

The proposals target the places where the *documented* architecture and the *actual* code have drifted apart, where one type does too many jobs, or where a structural choice taxes every future change.

---

## The proposals

### P1 — Split LinkCleanKit into layered targets

**Current state.** `LinkCleanKit` is a single SPM target containing four very different kinds of code:

- Pure domain logic with zero dependencies: `URLCleaner`, `TrackingParameterCatalog`, `ReferenceParameterCatalog`, `MarkdownFormatter`, `OnboardingDemo`, `AnalyticsEvent`, `Entitlement`, `ReviewGate`.
- Persistence over UserDefaults and SwiftData: `TrackingParameterStore`, `SettingsStore`, `EntitlementStore`, `HistoryEntry`/`HistoryContainer`/`HistoryRecorder`.
- An SDK binding: `TelemetryDeckAnalytics` (pulls the TelemetryDeck package into everything).
- UIKit presentation: `ActionExtensionViewController` with ~90 lines of toast layout code.

Because one corner of the target needs UIKit and `Bundle.module`, the whole package sets `defaultIsolation(MainActor.self)` — and then the *majority* of declarations opt back out with explicit `nonisolated` (17+ types). The defaults are inverted: the package-wide rule serves the minority. Two further taxes: `swift test` cannot run on macOS at all (UIKit import), so even pure `URLCleaner` tests require booting an iOS 26.5 simulator; and TelemetryDeck is a transitive dependency of the URL cleaner.

**What I'd change.** One package, four targets, with compiler-enforced dependency direction:

```
LinkCleanCore        – pure domain. No dependencies, no resources, default nonisolated.
                       URLCleaner, CleanOutcome (P2), TrackingParameter*, ReferenceParameterCatalog,
                       MarkdownFormatter, OnboardingDemo, AnalyticsEvent, Entitlement, ProGate (P9),
                       review-gate rules (P7), SettingsKeys, AppGroup.
LinkCleanData        – persistence. Depends on Core. SwiftData models + container,
                       TrackingParameterStore, SettingsStore, EntitlementStore, HistoryStore (P8),
                       LinkMetadataService (P8), CleaningService (P2).
LinkCleanAnalytics   – the TelemetryDeck binding. Depends on Core (+Data for the entitlement
                       default parameter). AnalyticsService protocol + TelemetryDeckAnalytics.
LinkCleanExtensionUI – MainActor, UIKit. Depends on all of the above. The extension pipeline (P5),
                       toast view, and the only string catalog left in the package (P3).
```

App and extension targets import what they need; `Core` and `Data` compile and test on macOS.

**Why.** This is the keystone change — most other proposals get cheaper because of it:

- `swift test` on the Mac for the entire domain + persistence layer: the feedback loop drops from "boot a simulator" to milliseconds (P12).
- The `defaultIsolation(MainActor)` / `Bundle.module` conflict that forces the kit's exceptional localization style is confined to one tiny UI target instead of constraining the whole package (P3).
- ~17 `nonisolated` annotations disappear in Core because the default finally matches the contents.
- The TelemetryDeck SDK stops being a dependency of the URL cleaner; a future SDK swap touches one target.
- Dependency direction becomes a compile error instead of a convention: domain code physically cannot reach UIKit, SwiftData, or the analytics SDK.

---

### P2 — One `CleanOutcome`, one parse, privacy enforced by type

**Current state.** A single clean produces its data through four overlapping shapes and repeated parsing:

- `URLCleaner.cleanResult(...)` → `CleanResult` (counts, kind IDs, reference matches — the analytics-safe view). One `URLComponents` parse.
- `URLCleaner.removedParameterNames(...)` → display names. A second parse of the same string.
- `URLCleaner.leftoverParameterNames(...)` → more display names. A third parse.
- The app then re-bundles all of it into `LinkClean/Shared/Models/CleanedURL.swift`, an almost field-for-field copy of `CleanResult` plus the name arrays and an `id`.

`DefaultURLCleaningService.clean` calls the first three in sequence — and `refreshCleanedURL` runs on every keystroke, with `isValidURL` adding a fourth parse. Meanwhile, both action extensions hand-compose the identical pipeline (`parameterStore.enabledParameters(forHost: URLCleaner.ruleHost(of: url))` → `URLCleaner.cleanResult`) instead of sharing the service. And the critical privacy rule — *raw query-key names must never reach analytics* — is enforced only by doc comments on `CleanedURL.removedNames`/`leftoverNames` and on the two name-list functions.

Finally, `AnalyticsEvent.homeURLCleaned` and `.actionCleanSucceeded` each take the same six loose fields (`changed`, `removedCount`, `leftoverCount`, `referenceMatchCount`, `removedKinds`, `domain`), re-plumbed by hand at every call site.

**What I'd change.** One domain type, produced in a single pass over the query items, with the privacy boundary expressed as nested types:

```swift
public struct CleanOutcome: Sendable, Equatable {
    public let input: String
    public let cleaned: String

    /// The only part an analytics event can accept. No raw names except
    /// reference-catalog matches, by construction.
    public struct Telemetry: Sendable, Equatable {
        public let changed: Bool
        public let removedCount: Int
        public let leftoverCount: Int
        public let removedKindIDs: Set<String>
        public let referenceMatches: [String]   // public catalog names only
        public let domain: String               // via analyticsDomain(from:)
    }
    public let telemetry: Telemetry

    /// On-device display only. Nothing in AnalyticsEvent accepts this type.
    public struct Display: Sendable, Equatable {
        public let removedNames: [String]
        public let leftoverNames: [String]
    }
    public let display: Display
}
```

- `URLCleaner` exposes one entry point returning `CleanOutcome`; the three current functions and `CleanResult` fold into it (the removed/leftover name lists fall out of the same loop that already classifies every query item).
- `AnalyticsEvent.homeURLCleaned(source:telemetry:)` and `.actionCleanSucceeded(telemetry:)` take the `Telemetry` value. The compiler now guarantees a `Display` name can't be routed into an event without a deliberate, reviewable type conversion.
- `CleanedURL` in the app dies. Home holds a `CleanOutcome` (identity for SwiftUI comes from `input`/`cleaned`, which is what the dedup logic keys on anyway).
- One `CleaningService` (protocol + default impl) lives in `LinkCleanData` — store + host resolution + cleaner in one place — consumed by HomeViewModel **and both extensions**, deleting the three hand-rolled compositions.

**Why.** Four parses per keystroke become one (cheap, but it's also four chances for the shapes to disagree). Two hundred lines of parallel API and a duplicated app-side model disappear. Most importantly, the project's strongest invariant — its privacy taxonomy — stops living in comments and starts living in the type system, which is the difference between "reviewed carefully in June 2026" and "cannot regress."

---

### P3 — No strings in the domain

**Current state.** The kit owns user-facing strings in two places, and both are the documented warts of the codebase:

- `TrackingParameterKind.title` is `@MainActor` because `Bundle.module` is MainActor-isolated under the package's forced isolation — a domain *value type* that can only be fully read on the main actor.
- The toast strings (`toast.copied`, `toast.noLinkFound`) use the explicit-key style because the kit's catalog must contain no `manual` entries (Xcode's generated-symbol code conflicts with the package isolation). CLAUDE.md has to document this exception at length.

**What I'd change.** With P1 in place:

- `TrackingParameterKind` loses `title` entirely. The domain ships identifiers (`"utm"`, `"ads"`); `ManageParametersView` maps `kind.id` to the app target's generated symbols (`.parametersKindUtm`…), where localization already works uniformly. A `default:` falls back to the raw id, exactly as today.
- The toast strings move into `LinkCleanExtensionUI` — the one target that is genuinely MainActor UI — or the extension pipeline (P5) returns a semantic `ToastKind` (`.copied`, `.noLinkFound`) that the UI layer localizes.
- `LinkCleanCore` and `LinkCleanData` end up with **no string catalog, no resources, no `defaultLocalization`**.

**Why.** The entire "LinkCleanKit is the exception" localization rule — a standing trap for every future contributor and the longest paragraph in CLAUDE.md — exists to serve about ten strings. Move the strings to the layers that present them and the exception, the `@MainActor` property on a `Sendable` struct, and the CLAUDE.md caveat all evaporate. Domain types carrying display text was the root mistake; identifiers out, localization at the edge.

---

### P4 — A real composition root

**Current state.** `ARCHITECTURE.md` promises a composition root ("constructs dependencies once… one real wiring path"). In practice there isn't one. Every ViewModel default-constructs production services in its initializer:

```swift
init(service: URLCleaningService = DefaultURLCleaningService(),
     analytics: AnalyticsService = TelemetryDeckAnalytics(),
     settings: SettingsStore = SettingsStore(), ...)
```

and every view default-constructs its ViewModel (`init(viewModel: HomeViewModel = HomeViewModel())`). That's nine independent wiring points, each silently choosing production implementations. `LinkCleanApp` wires only `EntitlementsModel`. Consequences: there is no single place to swap an implementation app-wide (e.g. a console-logging `AnalyticsService` in DEBUG); the dependency graph is invisible at the root; and dependencies that *should* be shared singletons (one `EntitlementsModel`) follow a different mechanism (SwiftUI environment) than everything else (default args), so `SettingsViewModel.restorePurchases(using:)` has to take the model as a *method parameter* because init-time injection can't reach the environment.

**What I'd change.** Make the documented architecture real, with the lightest mechanism that works:

```swift
@MainActor
struct AppDependencies {
    let cleaning: CleaningService
    let analytics: AnalyticsService
    let settings: SettingsStore
    let parameters: TrackingParameterStore
    let review: ReviewService
    let history: HistoryStore          // P8
    let entitlements: EntitlementsModel

    static func live() -> AppDependencies { ... }     // built once in LinkCleanApp.init
    static func preview() -> AppDependencies { ... }  // stubs for #Preview
}
```

- Inject via the SwiftUI environment with an `@Entry` key; owning views construct their ViewModel from it: `HomeView` reads `deps` and does `_viewModel = State(initialValue: HomeViewModel(deps:))` — or, simpler, each feature view keeps a convenience init taking `AppDependencies`.
- ViewModel initializers **lose production defaults**. Tests construct them with explicit doubles exactly as they already do; nothing else may construct one implicitly.
- `TelemetryDeckAnalytics.start(surface:)` is called by `AppDependencies.live()` — SDK lifecycle and instance creation finally live in the same place.
- `PreviewEntitlementsService` moves out of the production target into preview/test support (today it ships in the app binary).

**Why.** Default-argument injection is fine for leaf utilities, but here it hides the app's object graph and forks the wiring mechanism in two. One `live()` function makes the graph reviewable at a glance, gives DEBUG/screenshot builds a single interception point (today `-screenshotMode` has to suppress analytics via a static guard inside the SDK wrapper), and removes the awkward pass-the-model-per-call pattern. It also makes the next three proposals (P6, P8, P9) cheap: new collaborators slot into one place.

---

### P5 — Extensions: pipeline + strategy instead of base-class inheritance

**Current state.** `ActionExtensionViewController` is an `open class` doing template-method inheritance: URL extraction (NSItemProvider plumbing), history persistence, the onboarding success signal, haptics, analytics startup, toast rendering, and dismissal — with two subclasses overriding `processInputItems`. Both subclasses then duplicate the same tail by hand, in the same order, with the same comments: clean → write pasteboard → capture success event → emit reference-observed events → `saveHistory` → `recordSuccessfulRun` → `playSuccessHaptic` → `showToastThenDismiss`. The Markdown extension additionally has a private `fetchTitle(for:)` that re-wraps `LPMetadataProvider`, duplicating the app target's `DefaultLinkMetadataService`.

The flow logic is untestable below the `UIViewController` line — kit tests for it exist (`ActionExtensionViewControllerTests`) but have to exercise a view controller to test what is really a pipeline of pure steps.

**What I'd change.** Composition in `LinkCleanExtensionUI`: one pipeline, parameterized by an output strategy.

```swift
struct ActionPipeline {
    let surface: AnalyticsSurface              // .clean / .markdown
    let strategy: any ActionOutputStrategy

    func run(_ context: ExtensionInput) async -> ActionPresentation
    // extract URL → clean via CleaningService (P2) → strategy.payload(outcome)
    // → write pasteboard → events → history → success signal
    // returns .toast(.copied) / .toast(.noLinkFound) + haptic kind
}

protocol ActionOutputStrategy {
    func payload(for outcome: CleanOutcome) async -> PasteboardPayload
}
struct CleanLinkStrategy: ActionOutputStrategy { ... }      // URL out
struct MarkdownLinkStrategy: ActionOutputStrategy { ... }   // JS title / LPMetadata / URL-only
```

A single thin `ActionHostViewController` (shared, ~40 lines) gathers `extensionContext` input, runs the pipeline, and renders the returned `ActionPresentation`. Each extension target becomes a configuration file: pick a strategy, pick a surface. The toast becomes a small SwiftUI view hosted in a `UIHostingController` — the last hand-rolled UIKit layout in the project goes away.

**Why.** The two `processInputItems` bodies are the most duplicated logic in the codebase, and inheritance is why: shared *steps* live in the base class but the shared *sequence* can't, so each subclass restates it. A pipeline makes the sequence the shared artifact, makes it unit-testable without UIKit (extraction and strategies tested as values), and makes a third extension — "Copy as HTML", "Clean & Open" — a ~20-line strategy instead of a fourth copy of the ritual. The JS-preprocessing title path and `LPMetadataProvider` fallback fold into `MarkdownLinkStrategy` using the shared `LinkMetadataService` (P8), deleting the duplicate fetcher.

---

### P6 — Model the clean-session lifecycle; un-cram HomeViewModel

**Current state.** `HomeViewModel` is 415 lines holding at least six jobs: input sanitation and paste-vs-type classification, clean orchestration with task cancellation, copy/share export, history recording, review-prompt orchestration, and analytics emission. Its hardest logic is invisible: **five** parallel dedup keys (`lastSignaledCleanInput`, `lastCopiedOutput`, `lastSharedOutput`, `lastRecordedHistoryOutput`, `lastReviewCountedOutput`) with deliberately *pairwise-different* reset rules — e.g. clearing the input resets the first four but intentionally not the fifth, copy and share dedupe separately but share one history row, a leftover-pill refine re-arms copy/share but not the cleaned signal. Each rule is correct and each is documented, but the invariants live as field interactions spread across 100 lines of `didSet` and handler code. The review flow alone spans seven fields and five methods here, plus sheet wiring and `requestReview` plumbing in `HomeView`, plus three types in the kit (`ReviewGate` + `ReviewService` + `DefaultReviewService`).

**What I'd change.** Extract the two stateful sub-machines into purpose-built types; the ViewModel becomes a thin coordinator.

1. **`CleanSession`** (pure struct, `LinkCleanCore`): the lifecycle of one input → outcome → exports. It owns the dedup keys and exposes intent: `beginInput(_:)`, `setOutcome(_:)`, `noteCopy() -> CopyEffects`, `noteShare() -> ShareEffects`, where the returned effects say exactly what fires (`signalExport: Bool`, `recordHistory: Bool`, `countForReview: Bool`). All five invariants become table-driven unit tests in the fast macOS suite — `clear-then-repaste does not re-count review`, `refine re-arms export but not cleaned-signal` — instead of emergent behavior.
2. **`ReviewPromptFlow`** (`@Observable`, app target): owns eligibility check, the once-per-session cap, the 0.6 s grace delay, presentation state, the rated-high → system-prompt handoff. `HomeView` renders `flow.isPresenting` and calls `flow.handle(outcome)`; `HomeViewModel` only calls `flow.noteExport()`. The kit's `ReviewGate` static enum folds into an instance `DefaultReviewService` (P7), collapsing three review types into two.

`HomeViewModel` keeps what is genuinely its job: text-field sanitation, paste-source classification, task lifecycles, and translating session effects into service calls.

**Why.** This is the file every future Home feature must wade through, and its risk is concentrated precisely where there is no type structure: the dedup bookkeeping. Encoding the ledger as a value type with intent methods turns "remember to also reset X when Y" into an exhaustively tested transition function, shrinks HomeViewModel to ~200 readable lines, and gives the review flow one owner instead of two-and-a-half.

---

### P7 — One persistence map; stores all the way down

**Current state.** `SettingsStore` was created to be "the single source of truth" for key-suite-default triples — but coverage stopped at two keys. Around it:

- `LinkCleanApp.init` writes `hasCompletedOnboarding` raw in four places and reads a **hard-coded string** (`"screenshotFixtures"`) that exists in no key registry.
- `ContentView` reads onboarding via `@AppStorage`; the app entry writes the same key via `UserDefaults.standard` — two mechanisms for one flag.
- `lastActionExtensionRunAt` is raw-read in `ExtensionGuideViewModel` and raw-written in `ActionExtensionViewController`.
- `ReviewGate` and `TrackingParameterStore` keep private key constants outside `SettingsKeys`, contradicting ARCHITECTURE.md's "all keys defined in SettingsKeys."
- `ReviewGate` is a static enum requiring `defaults:` parameters threaded through every call, plus the separate `ReviewService` protocol + `DefaultReviewService` adapter just to make it injectable — three declarations for one concept.
- The debug entitlement override key lives as a static on `StoreKitEntitlementsService`, and `EntitlementsModel`'s DEBUG path reads it through the concrete class.

**What I'd change.**

- `SettingsStore` (in `LinkCleanData`) becomes the complete typed facade: `hasCompletedOnboarding`, `lastActionExtensionRunAt`, `screenshotFixturesPath` (DEBUG), with each accessor declaring its suite. Views needing live reactivity keep `@AppStorage(SettingsKeys.…)` — same constant, same suite — but every *write* goes through the store.
- `ReviewGate`'s logic moves into `DefaultReviewService` as an instance constructed with its suite (the pure threshold math can stay a tiny `nonisolated` function set in Core for direct testing). One protocol, one implementation, zero statics.
- A `DebugEntitlementOverrideStore` (DEBUG-only, `LinkCleanData`) owns the override key; both the StoreKit service and the developer menu consume it, decoupling `EntitlementsModel` from the concrete service class.
- `SettingsKeys` stays the single key registry, now actually exhaustive, with a doc-comment table of *key → suite → writer(s) → reader(s)* — the cross-process contract on one screen.

**Why.** UserDefaults is this app's IPC bus between three processes; today you reconstruct the contract by grepping. Completing the facade makes the bus discoverable, deletes the static/instance double-pattern around the review gate, and removes the one genuinely stringly-typed key in the repo. All of this is mechanical and independently shippable — the cheapest proposal here.

---

### P8 — A `HistoryStore` service; one write path, one metadata fetcher

**Current state.** History has two write paths with different semantics — extensions go through `HistoryRecorder.save` (fresh context, explicit `save()`), the app inserts into `mainContext` and relies on autosave — and the app path requires the `setModelContext(_:)` dance: both `HomeViewModel` and `HistoryViewModel` hold an optional `ModelContext` injected from the view's `.task`, a silent no-op if the ordering ever breaks. Deletion logic is split between `HistoryViewModel` (single delete) and `SettingsViewModel` (`try? context.delete(model:)` twice, errors swallowed). Metadata enrichment lives inside `HistoryViewModel` as a hand-rolled task pool (cap-of-3 via a `Set`, task dictionary, cancel-on-disappear) mutating `@Model` objects, while the Markdown extension wraps `LPMetadataProvider` a second time for titles.

**What I'd change.** A `HistoryStore` in `LinkCleanData`, constructed once with the container (composition root, P4) and injected into ViewModels:

```swift
@MainActor @Observable
final class HistoryStore {
    init(container: ModelContainer, metadata: LinkMetadataService, settings: SettingsStore)
    func record(_ outcome: CleanOutcome)         // honors saveHistoryEnabled; explicit save
    func delete(_ entry: HistoryEntry)
    func clearAll() throws
    func enrich(_ entry: HistoryEntry)           // owns the fetch pool + cap
}
```

- Reads stay exactly as they are: `@Query` in `HistoryView`. The store is the *write* side only.
- `HistoryRecorder` folds in as the nonisolated `record` core both app and extensions share — one save semantics everywhere (explicit save, logged failures; today's silent `try?` in Settings gets a single logging policy).
- `LinkMetadataService` moves to `LinkCleanData`; the History enrichment pool and the Markdown extension's title fetch (P5) consume the same implementation.
- `setModelContext(_:)` is deleted from both ViewModels.

**Why.** The optional-context dance is the most fragile wiring in the app (a forgotten `.task` produces silently-dropped history, not an error), the dual write semantics is a latent inconsistency (autosave timing vs. explicit save), and the enrichment pool is infrastructure living inside a screen's ViewModel. One store gives history a front door, makes the write path testable with an in-memory container in the fast suite, and leaves the ViewModels with intent only.

---

### P9 — Entitlements: thinner stack, funnel analytics at the engine, policy in the domain

**Current state.** The purchase stack is well-layered at the bottom (`StoreKitEntitlementsService` is genuinely the only StoreKit-touching type) but frays above it:

- The purchase-funnel analytics is split across three owners: revenue (`recordPurchase`) in the service, `purchaseStarted/Completed/Failed` in `PaywallViewModel`, and `purchaseRestored` duplicated in **both** `PaywallViewModel.restore()` and `SettingsViewModel.restorePurchases(using:)` — two hand-kept copies of the same capture-and-classify logic, which also both reimplement "restore only grants" interpretation.
- `EntitlementsModel` is a pass-through for `proProduct`/`purchase`/`restorePurchases`, and `PaywallViewModel` depends on the concrete class — the one ViewModel in the app that can't take a protocol double.
- `ProGate` (the free-tier policy) lives in the app target while `Entitlement` and `EntitlementStore` live in the kit — even though `EntitlementStore`'s stated purpose is "so extensions can gate features," which would need the policy too.
- `AnalyticsEvent.PaywallTrigger` gets a `@retroactive Identifiable` conformance in `PaywallView.swift` so it can double as sheet-presentation currency.
- `AnalyticsService.recordPurchase(transaction: Transaction)` is untestable by construction — a `StoreKit.Transaction` cannot be instantiated in unit tests, so `SpyAnalytics` no-ops it and no test can assert revenue recording.

**What I'd change.**

- **Funnel at the engine.** `purchase()` and `restore()` on the service capture their own `Pro.Purchase.*` events (they already capture revenue; started/completed/failed/restored are facts the engine knows best). ViewModels render outcomes only; the Settings/Paywall duplication disappears.
- **One observable surface.** `EntitlementsModel` stays the app-facing type, but ViewModels depend on it through a small protocol (`EntitlementsProviding`) so the paywall is testable with a stub; the model keeps the stream consumption and grant-only restore semantics as its real job.
- **Policy into Core.** `ProGate` moves next to `Entitlement` in `LinkCleanCore`; the kit owns the whole question "what may a free user do," ready for extension-side gates.
- **Split the analytics protocol.** `AnalyticsService` (events only, Core-friendly) and `RevenueRecording` (StoreKit-coupled, implemented by `TelemetryDeckAnalytics`, consumed only by the StoreKit service). Spies implement the former completely; the StoreKit seam stops infecting every analytics consumer with a StoreKit import.
- **Presentation currency in the app.** A tiny `PaywallRoute` (or just declaring the `Identifiable` conformance in the kit next to the enum) replaces the retroactive conformance.

**Why.** Funnel events that fire from two different ViewModels will eventually disagree (one already differs subtly: Settings restore failure and "nothing to restore" both emit `restored: false`, Paywall additionally surfaces different alerts). Emitting each business fact from the layer that establishes it is the same principle the codebase already applies to revenue — finishing the job removes the duplication and makes the funnel trustworthy. The rest is alignment: policy with its domain, protocols where doubles are needed, conformances where their type lives.

---

### P10 — Pro-gate decisions out of Views

**Current state.** The project's own rule — "no business logic in View button/action closures" — is violated at exactly the monetization gates. `HomeView.confirmAlwaysRemove()` reads the entitlement, counts custom rules via `viewModel.customParameterCount`, branches on `ProGate.canAddCustomRule`, and schedules a 400 ms sleep before raising the paywall. `CustomParametersView` computes its own gate condition in the view (`!ProGate.canAddCustomRule(...)`) to decide between adding and presenting.

**What I'd change.** Each gate becomes a ViewModel intent returning a decision:

```swift
enum GateResult { case allowed; case gated(PaywallRoute) }
// HomeViewModel
func requestAlwaysRemove(_ name: String, entitlement: Entitlement) -> GateResult
```

The view maps `.allowed` to haptic + dismiss and `.gated` to setting the sheet trigger (the dialog-dismiss grace delay stays in the view — it *is* presentation timing). `CustomParametersViewModel` gets the same treatment. The `.paywallSheet` modifier and per-view trigger `@State` stay as they are — they're idiomatic SwiftUI and don't need a router.

**Why.** Gating is the highest-stakes branch in the app (it's the revenue path) and currently the least tested: it lives in view closures that no unit test exercises, while `ProGateTests` covers only the pure math. Moving the decision into ViewModels puts the entitlement+count+policy composition under the existing test pattern with one small enum. Deliberately minimal — no presenter object, no environment router — because five call sites don't justify machinery.

---

### P11 — Slim the app entry: `DebugLaunchConfigurator`

**Current state.** `LinkCleanApp.swift` is 181 lines, of which ~120 are launch-argument handling: UI-test domain wipes, screenshot-state preparation, sample-URL seeding, 50 lines of inline sample-history fixtures with thumbnail-fixture resolution, and review-gate forcing. The production wiring — container, analytics start, entitlements — is eight lines buried in the middle.

**What I'd change.** A DEBUG-compiled `DebugLaunchConfigurator` (app target, `App/Debug/`):

```swift
#if DEBUG
struct DebugLaunchConfigurator {
    static func apply(arguments: [String], container: ModelContainer,
                      settings: SettingsStore, parameters: TrackingParameterStore)
}
#endif
```

owning all launch-arg branches and the fixture data; `LinkCleanApp.init` becomes: build dependencies (P4), `#if DEBUG apply(…) #endif`, done. The fixture samples move with it.

**Why.** The app entry is the first file anyone reads and currently the least representative of the app. Pure relocation — zero behavior change, immediate readability win, and the seeding logic gains a natural home for the inevitable next launch flag. Quick win; do it first.

---

### P12 — Two-speed test architecture

**Current state.** All tests require an iOS 26.5 simulator: kit tests because the package imports UIKit, app tests because they're an Xcode target. The two suites are run by two schemes with no umbrella (a known bite: a kit enum change compiles clean in the kit scheme and breaks `LinkCleanTests` — you must remember to run both). Test doubles aren't shared: `SpyAnalytics` exists only in app tests, so kit-side code that captures analytics has no spy available.

**What I'd change.** Falls out of P1, plus two small additions:

- **Fast lane:** `LinkCleanCoreTests` + `LinkCleanDataTests` run with `swift test` on macOS — the URL cleaner, catalogs, stores, `CleanOutcome` (P2), `CleanSession` (P6), review-gate rules, `ProGate`, history writes (in-memory container). This is where the dense logic lives, and it now runs in seconds locally and in CI without a simulator.
- **Sim lane:** app-target ViewModel tests + `LinkCleanExtensionUI` pipeline tests, run on the simulator as today.
- A `LinkCleanTestSupport` target in the package (spies, stub services, fixture URLs) imported by both suites — one `SpyAnalytics`, not per-suite copies.
- One Xcode **test plan** that runs both schemes, so "run the tests" is a single action and the cross-target compile break can't slip through.

**Why.** The feedback loop is the multiplier on every other proposal: logic extracted in P2/P6/P7/P8 only pays off if testing it is instant. Today the floor is "boot a simulator"; after this the floor is `swift test` in the package directory.

---

## Implementation order

Ordered for quick wins first, then dependency-driven. Every step compiles, keeps both suites green, and is independently shippable. Sizes: **S** ≈ hours, **M** ≈ a day-ish, **L** ≈ a few days.

| # | Step | Proposals | Size | Depends on |
|---|------|-----------|------|------------|
| 1 | `DebugLaunchConfigurator`: move all launch-arg/fixture code out of `LinkCleanApp` | P11 | S | — |
| 2 | Complete the persistence map: `SettingsStore` coverage, `ReviewGate` → instance `DefaultReviewService`, debug-override store, key/suite table | P7 | S | — |
| 3 | Alignment batch: `ProGate` → kit beside `Entitlement`; `PaywallTrigger` Identifiable out of retroactive land; dedupe restore analytics into one place | P9 (part) | S | — |
| 4 | Gate decisions into ViewModels (`requestAlwaysRemove`, custom-param gate) + tests | P10 | S | 3 |
| 5 | **Package split**: Core / Data / Analytics / ExtensionUI; strings out of the domain (kind titles → app UI, toast strings → ExtensionUI); Core goes default-`nonisolated` | P1, P3 | L | 2, 3 |
| 6 | Two-speed tests: macOS `swift test` for Core/Data, `LinkCleanTestSupport`, umbrella test plan | P12 | S | 5 |
| 7 | `CleanOutcome` single-pass with `Telemetry`/`Display` tiers; delete `CleanResult` + `CleanedURL` + name-list APIs; shared `CleaningService` consumed by Home and both extensions; analytics events take `Telemetry` | P2 | M | 5 |
| 8 | Composition root: `AppDependencies.live()/preview()`, environment injection, strip production defaults from ViewModel inits, move `PreviewEntitlementsService` out of the app binary | P4 | M | 5 |
| 9 | Extension pipeline: `ActionPipeline` + strategies + shared host VC; SwiftUI toast; both extension targets become configs | P5 | M | 5, 7 |
| 10 | `CleanSession` ledger + `ReviewPromptFlow`; `HomeViewModel` slims to coordination | P6 | M | 7, 8 |
| 11 | `HistoryStore` + unified `LinkMetadataService` (History enrichment + Markdown titles); delete `setModelContext` | P8 | M | 8 (9 for the shared fetcher) |
| 12 | Entitlements finish: funnel analytics at the engine, `EntitlementsProviding` protocol for the paywall, `AnalyticsService`/`RevenueRecording` split | P9 (rest) | M | 8 |
| 13 | Rewrite `ARCHITECTURE.md` (and the CLAUDE.md localization section) to describe the *actual* architecture: layer map, persistence table, dependency-injection rules | — | S | all |

Sequencing notes:

- **Steps 1–4 are a single quick-win sprint** — all small, all independent of the package split, each individually mergeable. They pay for themselves even if nothing else ships.
- **Step 5 is the gate.** It's the largest mechanical change (file moves + manifest + import fixes, near-zero logic change), and steps 6–12 all get materially cheaper after it. Do it in one focused PR while the tree is otherwise quiet.
- **Steps 7 and 8 unlock the rest** and can land in either order; 9–12 then parallelize freely (extension-side vs. app-side don't collide).
- "No backward compatibility" is exercised in steps 2 and 7 (UserDefaults accessor reshuffles, deleted public kit APIs). Persisted *user data* (history store, parameter overrides, entitlement snapshot) keeps its existing keys throughout — not for compatibility's sake, but because renaming them buys nothing.
- After step 13, the documentation debt is zero: the architecture documents describe the system as built, including the parts (composition root) that today exist only on paper.
