# Architecture (SwiftUI MVVM + Observation)

This repo uses a minimal, product-oriented MVVM architecture for small SwiftUI features:
- Clear ownership (who creates state, who mutates it)
- Testable business logic (ViewModels don’t depend on system singletons)
- Safe concurrency (UI state on main; background work off-main where appropriate)

## Defaults in This Repo
- iOS 18+ / iPadOS 18+
- Swift 6.2
- Default actor isolation is `MainActor` (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- Observation framework (`@Observable`) + SwiftUI ownership via `@State`

## Layers (plus a Composition Root)

Composition Root (App / top-level feature entry)
  ↓ constructs dependencies once
View (SwiftUI)
  ↓ renders state + forwards user intent
ViewModel (`@Observable`, `@MainActor`, `final`)
  ↓ coordinates work, owns screen state
Services (protocol → implementation; `Sendable`; actors for mutable state)
  ↓ I/O, persistence, side effects, domain operations
Models (domain types; framework-agnostic)

## Composition Root (Dependency Wiring)
**Goal:** dependency injection without global singletons.
- Construct real services at the top (in `App` or the highest-level feature container).
- Inject services into ViewModels via init.
- Previews/tests pass stubs/mocks.

Recommended pattern:
- One “real” wiring path (production)
- Many lightweight wiring paths (previews/tests)

## Models
**Goal:** predictable state and reusable domain logic.
- Prefer plain Swift types (usually `struct`) with value semantics.
- Conform to `Identifiable` only when the UI needs stable identity.
- Avoid importing SwiftUI in domain models.

If using SwiftData:
- Persistence types (`@Model`) may differ from domain models; map in the service layer when useful.

## Services
**Goal:** isolate side effects and I/O behind testable boundaries.
- Define a protocol for each capability (e.g. cleaning URLs, persistence, clipboard, haptics, networking).
- Prefer **sync** APIs for pure/cheap transforms.
- Use **async throws** for I/O or work that can suspend/fail.
- Mark service protocols `Sendable`.
- Put mutable shared state behind an `actor` when needed.

**Rule of thumb:** if it touches the outside world (disk, network, pasteboard, haptics, analytics), it’s a service.

## ViewModels
**Goal:** one place for screen state + business rules.
- One ViewModel per screen/feature: `@MainActor @Observable final class`.
- Expose intent-based methods (named after user actions).
- Keep dependencies and internal tasks out of observation using `@ObservationIgnored`.

Async behavior conventions:
- Model loading/error/ready explicitly (avoid “hidden” loading flags scattered around).
- Cancellation rule: when a new intent supersedes an old one, cancel the old work (“latest wins”).
- Only update UI state on the main actor.

## Views
**Goal:** render state; forward intent; no business rules.
- The owning view stores the ViewModel in `@State` for stable lifetime.
- Use `@Bindable` inside `body` when you need bindings to observable properties.
- Use `.task {}` for lifecycle-bound async work (auto-cancels when the view disappears).
- Presentation-only logic is fine (formatting, conditional rendering); business rules stay in the ViewModel.

## Testing & Previews
**Goal:** fast tests that don’t hit real side effects.
- Unit test ViewModels by injecting mocked services.
- Prefer deterministic dependencies (e.g. injectable “clock/sleeper”) rather than `Task.sleep` in tests.
- Use Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`).

## Repo Notes (Shared Logic)
This repo includes shared logic used by multiple targets (e.g. app + action extension).
- Keep pure, framework-agnostic domain logic in shared modules (e.g. `LinkCleanCommon`).
- Keep target-specific UI and side effects in the target.
- When the extension must use UIKit, apply the same separation: minimal controller orchestration + shared domain/services underneath.
