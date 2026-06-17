## Platform
iOS 26+ · iPadOS 26+ · Swift 6.2 · SwiftUI · SwiftData

## Build Settings
Default actor isolation is **MainActor** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`). Use `nonisolated` to opt out for background work.

## Before Writing New Code
Find the closest existing example in the codebase and match its pattern.
If no precedent exists, state that explicitly before choosing an approach.

## Collaboration
- Stop and ask the user when unsure about requirements, scope, or approach.
- Hand off tasks that require Xcode GUI or Apple Developer portal: creating targets, configuring App Groups, entitlements, signing, capabilities, adding frameworks via Xcode UI.
- When handing off, state exactly what needs to be done so the user can act quickly.

## Patterns

**Observation:** `@Observable` classes + `@State` in views. Never `ObservableObject`, `@Published`, or `@StateObject`.

**Architecture:** See `ARCHITECTURE.md`.

**SwiftData:** `@Model` for persistence, `@Query` for reactive fetches, `ModelContext` from environment only.

**On-Device AI:** `@Generable` structs for type-safe Foundation Models output. Check `SystemLanguageModel.default.availability` before use.

**UI:** Standard components inherit Liquid Glass automatically. Native `WebView`—no UIKit bridging.

**Localization (identifier keys + generated symbols):** `Localizable.xcstrings` keys are identifiers (`home.input.header`), not English text. In the app target every `extractionState:"manual"` entry compiles to a type-safe symbol (`STRING_CATALOG_GENERATE_SYMBOLS = YES`): dots stripped + camelCased (`home.input.header` → `.homeInputHeader`), `%@` keys become methods (`.customParametersDelete(parameter)`). Consume via `Text(.symbol)`; wrap in `Text(.symbol)` for `Button`/`Label`/`Toggle`/`Section`/`.navigationTitle`/`.alert`/`.accessibilityLabel`; use `String(localized: .symbol)` where a `String` is needed (`TextField` placeholder, ViewModel return values). **Domain types ship identifiers, not copy:** `TrackingParameterKind` carries `id` (`"utm"`); `ManageParametersView.sectionTitle(for:)` maps it to a generated symbol (`.parametersKindUtm`). **`LinkCleanExtensionUI` is the one exception:** it is the only kit target with a string catalog (the action-extension toast strings) and `defaultIsolation(MainActor.self)`, so its catalog has NO `manual` entries — Xcode's generated `#if SWIFT_PACKAGE` symbol code conflicts with `Bundle.module` being MainActor-isolated — and it uses explicit keys: `String(localized: "toast.copied", defaultValue: "Copied", bundle: .module)`. `LinkCleanCore`/`Data`/`Analytics` have no catalog and no resources.

## Testing
Swift Testing framework: `@Test`, `#expect`, `#require`.

Three lanes — pick by what changed:
- **Fast (LinkCleanKit/, macOS, <1s):** `cd LinkCleanKit && swift test` — runs Core + Data. ExtensionUI builds empty on macOS (UIKit-guarded).
- **Kit sim:** `cd LinkCleanKit && xcodebuild test -scheme LinkCleanKit -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` — adds ExtensionUI.
- **App:** `xcodebuild test -scheme LinkCleanTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` — ViewModel tests.

Only iOS 26.5 simulator runtimes are installed; iPhone 17 family is the default sim (also pinned in `.xcodebuildmcp/config.yaml`).

## Debugging
- **Logger** (`Log.app`/`Log.action` via `LinkCleanKit/Sources/LinkCleanCore/Log.swift`): use for permanently useful operational messages that stay in the codebase.
- **print()**: use for one-time investigation debugging — add, build & run, read logs, remove.

## Avoid
- Combine (use async sequences)
- GCD (use async/await, TaskGroup, actors)
- Force unwraps without documented invariants
- UIKit unless no SwiftUI equivalent exists
- `@AppStorage` in a View that has a ViewModel (ViewModel owns settings as stored properties, refreshed on appear)
- Business logic in View button/action closures (call a ViewModel method)
- Direct service/network calls from Views
- Two mechanisms reading the same underlying state in one screen

## Git
Only commit staged changes. Never stage additional files unless explicitly asked.

## File Placement
```
LinkClean/
  App/                      – Entry point, root ContentView
  Features/{FeatureName}/   – View + ViewModel pairs, feature-scoped types (current: Home, History, Onboarding, Stats, Settings, Paywall, QR, ExtensionGuide)
  Shared/Models/            – Domain types used across features
  Shared/Services/          – Service protocols and implementations
  Shared/UI/                – Reusable view modifiers, components
LinkCleanKit/               – Local package, one product ("LinkCleanKit"), four layered targets; consumers import the layers they use:
  Sources/LinkCleanCore/        – pure domain, nonisolated default, no deps/resources (URLCleaner + CleanOutcome [Telemetry/Display], CleanSession, catalogs, AnalyticsEvent + AnalyticsService protocol, Entitlement, ProGate, SettingsKeys, Log)
  Sources/LinkCleanData/        – persistence, →Core, MainActor default (SwiftData models + container, stores, CleaningService, HistoryStore + HistoryRecorder, LinkMetadataService, DefaultReviewService)
  Sources/LinkCleanAnalytics/   – →Core+Data, the only target linking the TelemetryDeck SDK (TelemetryDeckAnalytics)
  Sources/LinkCleanExtensionUI/ – →all, MainActor, UIKit (ActionPipeline + ActionOutputStrategy [Clean/Markdown] + URLExtraction + ActionHostViewController + toast catalog)
  Sources/LinkCleanIntents/     – →Core+Data, App Intents (Siri/Shortcuts/widgets) — CleanLinkIntent, CleanClipboardIntent, IntentHistory; linked by app + LinkCleanWidget
  Tests/                        – LinkCleanCoreTests + LinkCleanDataTests (macOS fast lane), LinkCleanExtensionUITests (sim, UIKit-guarded), LinkCleanTestSupport (shared SpyAnalytics/Stub/fixtures)
LinkCleanAction/            – Action extension target (a config: subclasses ActionHostViewController, picks a strategy)
```
Dependency direction is compiler-enforced: Core cannot reach UIKit, SwiftData, or the analytics SDK. Two-speed tests: `swift test` in `LinkCleanKit/` runs Core+Data on macOS in <1s (the ExtensionUI test target's UIKit dep is `.when(platforms: [.iOS])` + `#if canImport(UIKit)`, so it builds empty on macOS); ExtensionUI tests run via `xcodebuild test -scheme LinkCleanKit` on the simulator. Production wiring is the composition root `AppDependencies.live(container:)` (app target); see `ARCHITECTURE.md`.
