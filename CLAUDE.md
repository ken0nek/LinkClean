## Platform
iOS 18+ · iPadOS 18+ · Swift 6.2 · SwiftUI · SwiftData

## Build Settings
Default actor isolation is **MainActor** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`). Use `nonisolated` to opt out for background work.

## Before Writing New Code
Find the closest existing example in the codebase and match its pattern.
If no precedent exists, state that explicitly before choosing an approach.

## Patterns

**Observation:** `@Observable` classes + `@State` in views. Never `ObservableObject`, `@Published`, or `@StateObject`.

**Architecture:** See `ARCHITECTURE.md`.

**SwiftData:** `@Model` for persistence, `@Query` for reactive fetches, `ModelContext` from environment only.

**On-Device AI:** `@Generable` structs for type-safe Foundation Models output. Check `SystemLanguageModel.default.availability` before use.

**UI:** Standard components inherit Liquid Glass automatically. Native `WebView`—no UIKit bridging.

## Testing
Swift Testing framework: `@Test`, `#expect`, `#require`.

## Avoid
- Combine (use async sequences)
- GCD (use async/await, TaskGroup, actors)
- Force unwraps without documented invariants
- UIKit unless no SwiftUI equivalent exists
- `@AppStorage` in a View that has a ViewModel (ViewModel reads settings instead)
- Business logic in View button/action closures (call a ViewModel method)
- Direct service/network calls from Views
- Two mechanisms reading the same underlying state in one screen

## File Placement
```
LinkClean/
  App/                      – Entry point, root ContentView
  Features/{FeatureName}/   – View + ViewModel pairs, feature-scoped types
  Shared/Config/            – App-wide constants (SettingsKeys)
  Shared/Models/            – Domain types used across features
  Shared/Services/          – Service protocols and implementations
  Shared/UI/                – Reusable view modifiers, components
LinkCleanCommon/            – Shared with action extension (domain logic, SwiftData models, stores)
LinkCleanAction/            – Action extension target
```
