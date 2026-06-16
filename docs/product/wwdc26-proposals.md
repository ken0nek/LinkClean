# WWDC 2026 — Proposals for LinkClean

Research date: 2026-06-10. Sources: Apple developer docs, WWDC 2026 sessions 241, 269, 274, 210, 326.
Adversarial verification: 23/25 claims confirmed, 2 refuted (noted below).
Codebase-grounded corrections (2026-06-10): 2 further claims revised against the actual source — Foundation Models is **not yet in the codebase** (#1), and History does **not** use day-bucket grouping (#2). See the ⚠️ notes in those sections.

LinkClean targets **iOS 26+**. Core AI (iOS 27+) and PrivateCloudComputeLanguageModel are noted separately as forward-looking.

---

## Priority 1 — Ship soon

### 1. Explain leftover parameters with Foundation Models

**Status (2026-06-10): scaffolded.** First Foundation Models integration landed — `LinkClean/Shared/Services/ParameterExplanationService.swift` (`@Generable nonisolated struct ParameterExplanation` + `FoundationModelsParameterExplanationService`), wired through `HomeViewModel.prepareExplanation(for:)`/`explanation(for:)` and surfaced in the leftover confirm dialog (resolve-then-present, since an `.alert` message isn't reactive). Availability-gated, fails soft to the generic copy. Tests in `HomeViewModelExplanationTests`. Deferred: `GenerationOptions` tuning, `prewarm`, analytics, localized model output (see "Follow-ups" at section end).

**What:** When a user taps a leftover parameter pill on the Home screen, the confirm dialog currently shows a generic "Always remove this parameter?" prompt. Use `LanguageModelSession` to generate a one-line plain-English explanation of what the parameter does — e.g. `fbclid` → "Facebook click tracking, added when you click a link on Facebook."

**Why this fits LinkClean:** The core value prop is transparency. A user who understands *why* a parameter is tracking them is more likely to remove it — and more likely to trust the app. Fully on-device, no data leaves the device.

**Where:** `HomeViewModel` — already has the leftover parameter names locally. Add a `Foundation Models`-powered `explain(parameter:)` method, gate on `SystemLanguageModel.default.availability`, display inline in the confirm dialog.

**Pattern to introduce (corrected):** CLAUDE.md names `@Generable` structs as the *intended* pattern, but Foundation Models is **not yet used anywhere in the codebase** — verified 2026-06-10: zero hits for `@Generable`, `LanguageModelSession`, `SystemLanguageModel`, or `import FoundationModels`. This proposal is the **first** Foundation Models integration, not an extension of existing code. Define a small `@Generable` struct:

```swift
@Generable
struct ParameterExplanation {
    let oneLiner: String   // "Facebook click tracking, added when sharing via Facebook"
    let isTracking: Bool
}
```

**Effort (corrected):** Small–medium, not "small." The `@Generable` + `LanguageModelSession` path is **not** already in the codebase — this is greenfield. Budget for first-time framework setup: the availability gate (`SystemLanguageModel.default.availability`), session lifecycle, prompt design, and the `.unavailable` fallback all built from scratch. Self-contained, but not a one-line extension.

**Fallback:** If `.unavailable`, show the existing generic dialog unchanged.

**Follow-ups (not yet done):**
- **Tune `GenerationOptions`** — currently defaults; a low temperature + small `maximumResponseTokens` would make the one-liner more deterministic and factual.
- **`prewarm`** the session when the leftover section appears, to cut the tap→dialog latency the resolve-then-present design introduces.
- **Category hint** — pass `TrackingParameterCatalog.kindID(for:)` into the prompt for better accuracy on known names (kept the service catalog-decoupled for now).
- **Analytics** — no event added (taxonomy is owned by the analytics-audit skill); decide whether "explanation shown" is worth a signal.
- **Localized output** — the model one-liner is runtime English, prepended to localized guidance; fine while the app is en-US only, revisit when localizing.
- **Release build** — verified compiling + tests green in Debug only (system framework, low risk); confirm in a Release build before shipping.

---

### 2. SwiftData sectioned History with `@Query(sectionBy:)`

**What:** WWDC 2026 adds a `sectionBy:` parameter to `@Query` that produces grouped results natively — `_trips.sections` gives you an iterable collection of sections, each with an `id` and its items.

**Why this fits LinkClean:** ⚠️ **Premise correction (verified 2026-06-10):** `HistoryView` does **not** group entries into Today / Yesterday / Earlier. The actual structure (`HistoryView.swift:13`, `HistoryViewModel.archive(from:isPro:)`) is a flat `@Query(sort: \HistoryEntry.createdAt, order: .reverse)` split by **entitlement + a rolling 7-day window** — the T1 Pro gate (§9-A): a `visible` set inside the window plus a blurred, counted `teaser`/`olderCount` archive for non-Pro users. There is no chronological day-bucket sectioning. `sectionBy:` solves day-grouping, which this screen doesn't currently do — so it is **not** a clean drop-in. Rescope before adopting: it would only apply if History gains real date sections (a redesign), and even then the Pro-gate window split is orthogonal to day-bucketing.

**Where:** `HistoryView` / `HistoryViewModel` — the `@Query` for `HistoryEntry` (the actual `@Model`; there is no `CleanedURL` type).

**Example:**
```swift
@Query(sort: \.cleanedAt, order: .reverse, sectionBy: \.dayBucket)
private var history: [CleanedEntry]
// history.sections: iterable, each section has .id (the day bucket) and items
```

**Caveat:** The section key (`dayBucket`) must be a stored property on the `@Model` — not a computed property. May need a `dayBucket: String` stored property added to the model (set at write time: `"Today"`, `"Yesterday"`, `"Earlier"`), or use a `Date` truncated to midnight.

**Effort:** Small-medium. The query change is small; the section key storage may require a lightweight model migration.

---

### 3. `@State` macro migration (maintenance, do before Xcode 27 build)

**What:** Xcode 27 converts `@State` from a `DynamicProperty` property wrapper to a Swift macro. This changes lifecycle semantics for `@Observable` class instances held in `@State`: they now initialize lazily, exactly once per view lifetime. **Source-breaking:** a compile error occurs if a stored `@State` property has both a default value *and* an `init` assignment.

**Why this affects LinkClean:** Every `View` in LinkClean uses `@State private var viewModel = SomeViewModel()` — the canonical `@Observable` + `@State` pattern. This is the exact pattern the change targets. It will likely compile fine (and get the improved semantics for free), but needs a build verification before shipping on Xcode 27.

**Action:**
- Build with Xcode 27 beta.
- Watch for TN3211 compile errors ("cannot provide a default value alongside an init").
- Fix pattern: remove the `= SomeViewModel()` default if the `init` also sets it, or vice versa.

**Back-ported to iOS 17** — no deployment-target risk.

---

## Priority 2 — Next cycle

### 4. `ResultsObserver` for non-UI history counts

**What:** `ResultsObserver` is a new SwiftData type for observing query results outside SwiftUI views. It integrates with Swift Observation via `withContinuousObservation`, returning an `ObservationTracking.Token`.

**Why this fits LinkClean:** The review-prompt gate counts distinct exports across ≥24h. Currently this either lives in the ViewModel or is computed at `onAppear`. A `ResultsObserver` watching the history model could keep a live, reactive count without the view needing to be on screen — removing the `onAppear` fallback workaround.

**Where:** `ReviewPromptService` or wherever the export-count logic lives. Replace the `onAppear` fallback with a persistent observer token.

**Effort:** Medium. Requires understanding the token lifecycle (retain it somewhere permanent — `AppDelegate`/`LinkCleanApp`).

---

### 5. Swipe actions on the History `ScrollView`

**What:** `swipeActionsContainer()` extends swipe-action support from `List` to any `ScrollView` or lazy stack.

**Why this fits LinkClean:** If History ever moves from `List` to a `ScrollView`-based layout (e.g. for card-style rows or to support the new reorderable container APIs), swipe-to-delete would work without reverting to `List`.

**Where:** `HistoryView`. Low-risk to adopt even if it stays a `List` — the modifier is additive.

**Effort:** Tiny. One modifier swap. Prep work for any future History redesign.

---

### 6. `ToolbarOverflowMenu` for Settings toolbar (if actions grow)

**What:** `ToolbarOverflowMenu` is a new SwiftUI container for space-constrained toolbars. Items inside it collapse into a `…` overflow button when space is tight.

**Why this fits LinkClean:** Settings is currently light on toolbar items, but if a 1.x update adds per-screen toolbar actions (export, share, info), `ToolbarOverflowMenu` prevents toolbar crowding on compact widths without manual `.hidden` logic.

**Effort:** Near-zero when needed. Note for future toolbar work.

---

## Priority 3 — Forward-looking (iOS 27+ / speculative)

### 7. `PrivateCloudComputeLanguageModel` for longer-context parameter analysis

**What:** A `PrivateCloudComputeLanguageModel` with ~32K token context and three reasoning levels (`.light`, `.moderate`, `.deep`) is available **at no cloud cost** to Small Business Program members with fewer than 2M first-time downloads.

**Why this fits LinkClean:** LinkClean almost certainly qualifies (enrolled in SBP, <2M downloads at launch). For power-user scenarios — e.g. "explain all 12 parameters found in this URL at once" or generating a custom-parameter description from a URL — the extended context and reasoning levels would produce better output than the on-device model for complex cases.

**Caveats:**
- Requires iOS 26+ but the access mechanism (explicit opt-in vs. automatic) was not confirmed by research.
- Privacy posture: PCC claims no data retention, but review the privacy characteristics before using for URL content (even host-only).
- Use only as a fallback when `SystemLanguageModel.default.availability` returns `.unavailable` for the on-device model, or for explicitly user-triggered "explain more" flows.

**Effort:** Medium. API surface is the same `LanguageModelSession` — just initialized with `PrivateCloudComputeLanguageModel` instead of `SystemLanguageModel.default`. Gate on entitlement + availability.

---

### 8. Core AI (iOS 27+) — custom model for parameter classification

**What:** `CoreAILanguageModels` (iOS 27+) lets apps load and run curated open-source weights (Qwen, etc.) entirely on-device via `CoreAILanguageModel(resourcesAt:)`. Uses the same `LanguageModelSession` / `@Generable` ergonomics as the built-in model.

**Why this fits LinkClean:** A fine-tuned or few-shot-prompted small model specifically for tracking-parameter classification could be more accurate and faster than the general-purpose Apple Intelligence model for this narrow task — especially for obscure parameters the general model has no training signal on.

**Caveat:** iOS 27+ only. The model weights are app-supplied (not OS-cached), meaning app size impact. Bundle size and download gating need design. Not a near-term proposal — track for a potential 2.x release.

---

## What does NOT apply

| Announcement | Why not relevant |
|---|---|
| StoreKit `BillingPlanType` / monthly installments | LinkClean Pro is a non-consumable, not a subscription |
| `@Attribute(.codable)` | No current SwiftData model needs opaque persistence; all types are SwiftData-native |
| `navigationTransition(.crossFade)` | No multi-scene navigation in LinkClean |
| `Binding<T?> alert/confirmationDialog` | Already using standard alert APIs; no optional-binding gaps identified |
| `SwiftData @Query sectionBy` for Pro gating | Entitlement state is not a SwiftData query — it's `EntitlementStore` (UserDefaults-backed) |

---

## Sources

- WWDC 2026 session 241 — Foundation Models (multimodal, DynamicProfile, PCC)
- WWDC 2026 session 269 — SwiftUI: ContentBuilder, @State macro, reorderable containers, swipe actions
- WWDC 2026 session 274 — SwiftData: sectionBy, @Attribute(.codable), ResultsObserver
- WWDC 2026 session 210 — StoreKit 2: BillingPlanType
- WWDC 2026 session 326 — Core AI: CoreAILanguageModels, CoreAIImageSegmenter
- developer.apple.com/documentation/updates/swiftui
- developer.apple.com/documentation/FoundationModels
