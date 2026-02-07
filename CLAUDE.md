## Platform
iOS 18+ · iPadOS 18+ · Swift 6.2 · SwiftUI · SwiftData

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

## Testing
Swift Testing framework: `@Test`, `#expect`, `#require`.

## Debugging
- Prefer `print()` debugging first—it's simple and effective.
- Add prints, build & run, read logs, remove prints. Don't over-engineer logging.

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
  Features/{FeatureName}/   – View + ViewModel pairs, feature-scoped types
  Shared/Models/            – Domain types used across features
  Shared/Services/          – Service protocols and implementations
  Shared/UI/                – Reusable view modifiers, components
LinkCleanCommon/            – Shared with action extension (domain logic, SwiftData models, stores)
LinkCleanAction/            – Action extension target
```
