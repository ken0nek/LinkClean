## Platform
iOS 18+ · iPadOS 18+ · Swift 6.2 · SwiftUI · SwiftData

## Build Settings
Default actor isolation is **MainActor** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`). Use `nonisolated` to opt out for background work.

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
