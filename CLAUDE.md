## Overview
LinkClean strips tracking parameters from URLs before you share them. Two surfaces share one
engine: the SwiftUI app and Share-sheet **action extensions** (plain "Clean URL" + "Markdown
link"). Domain logic, SwiftData models, and stores live in the `LinkCleanKit` local package so
the app and both extensions stay in sync.

## Platform
iOS 26+ · iPadOS 26+ · Swift 6.2 · SwiftUI · SwiftData

## Targets
- **LinkClean** — the app (scheme `LinkClean`).
- **LinkCleanAction** — action extension: clean URL → clipboard + history.
- **LinkCleanMarkdownAction** — action extension: clean URL → Markdown link (`[title](url)`) via
  JS preprocessing (`Action.js`) with an `LPMetadataProvider` title fallback.
- **LinkCleanTests** — app unit tests. **LinkCleanUITests** — UI tests.
- **LinkCleanKit** — local Swift package; its own `LinkCleanKitTests`.

Both extension `ActionViewController`s subclass `LinkCleanKit/ActionExtensionViewController`
(shared orchestration: URL extraction, haptics, toast, history, dismiss) and only override
`processInputItems()`. Cleaner logic is `LinkCleanKit/URLCleaner.clean(_:removing:)` — never fork
it per target.

## Build Settings
Default actor isolation is **MainActor** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`). Use `nonisolated` to opt out for background work.

## Build & Tooling
- **Prefer the XcodeBuildMCP tools** over raw `xcodebuild` for build/run/test/UI on a simulator.
  Call `session_show_defaults` first; if project + scheme + simulator are set, `build_run_sim`.
- Raw fallbacks: build `xcodebuild -project LinkClean.xcodeproj -scheme LinkClean build`;
  test `xcodebuild -project LinkClean.xcodeproj -scheme LinkClean -destination 'platform=iOS Simulator,name=iPhone 16' test`;
  kit only `swift test` in `LinkCleanKit/`.
- **fastlane** (`fastlane/Fastfile`, Ruby pinned via `mise.toml`): `bump_version`, `bump_build`,
  `bump`, and `beta` (build + TestFlight). All lanes bump every app target together.
- **`/bump`** skill wraps version/build bumps (see `.claude/skills/bump/`).
- **Project MCP servers** (`.mcp.json`): `context7` (library docs — use for any framework/API
  question instead of memory), `sosumi` (Apple developer docs), `XcodeBuildMCP`.

## Before Writing New Code
Find the closest existing example in the codebase and match its pattern.
If no precedent exists, state that explicitly before choosing an approach.

## Collaboration
- Stop and ask the user when unsure about requirements, scope, or approach.
- Hand off tasks that require Xcode GUI or Apple Developer portal: creating targets, configuring App Groups, entitlements, signing, capabilities, adding frameworks via Xcode UI.
- When handing off, state exactly what needs to be done so the user can act quickly.

## Patterns

**Observation:** `@Observable` classes + `@State` in views. Never `ObservableObject`, `@Published`, or `@StateObject`.

**Architecture:** MVVM + Observation. One `@MainActor @Observable final class` ViewModel per
screen; services injected via init (no global singletons); domain models are framework-agnostic
value types. Full layering, composition-root, and async conventions in `ARCHITECTURE.md`.

**SwiftData:** `@Model` for persistence, `@Query` for reactive fetches, `ModelContext` from environment only. History stores (`HistoryEntry`, `HistoryContainer`, `HistoryRecorder`) live in `LinkCleanKit`.

**App Group:** shared data between app + extensions uses `UserDefaults(suiteName: AppGroup.identifier)` (`group.com.ken0nek.LinkClean`). App-only settings use `UserDefaults.standard`. All keys in `SettingsKeys` — never hard-code key strings.

**On-Device AI:** `@Generable` structs for type-safe Foundation Models output. Check `SystemLanguageModel.default.availability` before use.

**UI:** Standard components inherit Liquid Glass automatically. Native `WebView`—no UIKit bridging.

**Localization (identifier keys + generated symbols):** `Localizable.xcstrings` keys are identifiers (`home.input.header`), not English text. In the app target every `extractionState:"manual"` entry compiles to a type-safe symbol (`STRING_CATALOG_GENERATE_SYMBOLS = YES`): dots stripped + camelCased (`home.input.header` → `.homeInputHeader`), `%@` keys become methods (`.customParametersDelete(parameter)`). Consume via `Text(.symbol)`; wrap in `Text(.symbol)` for `Button`/`Label`/`Toggle`/`Section`/`.navigationTitle`/`.alert`/`.accessibilityLabel`; use `String(localized: .symbol)` where a `String` is needed (`TextField` placeholder, ViewModel return values). **LinkCleanKit is the exception:** its catalog must have NO `manual` entries — Xcode's generated `#if SWIFT_PACKAGE` symbol code conflicts with the package's `defaultIsolation(MainActor.self)` (`Bundle.module` is MainActor-isolated). The kit uses explicit keys instead: `String(localized: "toast.copied", defaultValue: "Copied", bundle: .module)`, resolved on MainActor (see `TrackingParameterKind.title`).

## Testing
Swift Testing framework: `@Test`, `#expect`, `#require`. Unit-test ViewModels by injecting mocked
services (e.g. `MockURLCleaningService`); add tests when changing URL-cleaning rules or UI flows.

## Debugging
- **Logger** (`Log.logger.debug(...)` via `LinkCleanKit/Sources/LinkCleanKit/Log.swift`): use for permanently useful operational messages that stay in the codebase.
- **print()**: use for one-time investigation debugging — add, build & run, read logs, remove.

## Avoid
- Combine (use async sequences)
- GCD (use async/await, TaskGroup, actors)
- Force unwraps without documented invariants
- UIKit unless no SwiftUI equivalent exists (extensions are UIKit `ActionViewController`s by necessity — keep them thin over `LinkCleanKit`)
- `@AppStorage` in a View that has a ViewModel (ViewModel owns settings as stored properties, refreshed on appear)
- Business logic in View button/action closures (call a ViewModel method)
- Direct service/network calls from Views
- Two mechanisms reading the same underlying state in one screen

## Git
Only commit staged changes. Never stage additional files unless explicitly asked.

## File Placement
```
LinkClean/
  App/                      – Entry point (LinkCleanApp), root ContentView
  Features/{FeatureName}/   – View + ViewModel pairs, feature-scoped types
                              (Home, History, Settings, Onboarding, ExtensionGuide)
  Shared/Models/            – Domain types used across features
  Shared/Services/          – Service protocols and implementations
  Shared/UI/                – Reusable view modifiers, components
  Localizable.xcstrings     – App catalog (manual entries → generated symbols)
LinkCleanKit/               – Local package shared with extensions:
                              URLCleaner, TrackingParameters(+Store), History*,
                              MarkdownFormatter, OnboardingDemo, AppGroup,
                              SettingsKeys, ActionExtensionViewController, Log
LinkCleanAction/            – Clean-URL action extension
LinkCleanMarkdownAction/    – Markdown-link action extension (+ Action.js)
docs/                       – Roadmap & planning (TODO.md, plans/, strategy/, product/)
fastlane/                   – Fastfile (versioning, TestFlight)
```
