# Plan 001: ai-C — on-device Smart Title refinement (in-app v1)

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. If anything in "STOP
> conditions" occurs, stop and report — do not improvise. When done, update this
> plan's status row in `docs/plans/README.md`.
>
> **Drift check (run first)**:
> `git diff --stat 685aff6..HEAD -- LinkClean/Shared/Services/ParameterAdvisor.swift LinkClean/Features/History LinkCleanKit/Sources/LinkCleanCore/MarkdownFormatter.swift`
> If any in-scope file changed since `685aff6`, compare the "Current state"
> excerpts against the live code before proceeding; on a mismatch, STOP.
>
> **Read `docs/plans/SEED.md` first** — the eight standing LinkClean decisions. This
> plan records only the ai-C-specific answers and implementation; "SEED §N"
> points there for the shared rationale.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED (Foundation Models device-gating + making a copy path async)
- **Depends on**: none
- **Category**: direction (feature)
- **Planned at**: commit `685aff6`, 2026-06-15

## Why this matters

LinkClean already ships six Pro copy-format presets that embed a page title —
`titleAndURL`, `html`, `quote`, `citation`, `slack`, `plainTitle`
(`LinkCleanKit/Sources/LinkCleanCore/LinkTemplate.swift:126-158`, all
`requiresPro: true`) — plus a free Markdown copy in History. But the title they
embed is the raw page title: `Product Name | Big Store — 50% OFF Buy Now!`.
ai-C runs an on-device Foundation Models pass to rewrite that to the essential
title (`Product Name`) before formatting (spec: `docs/product/ai-features.md:92-98`).
It is the **formats × on-device-AI** wedge — the two things the free market-leader
competitor (Clean Links) has *neither* of (`docs/strategy/competitor-clean-links.md:116-117`).

**This plan builds the reusable refinement service and ships the one in-app
surface that exists today (History Markdown copy).** The higher-value surface —
the Pro `{title}` formats applied in the share extension — is deferred (see
"Surfaces" below); the service this plan creates is what that later work will reuse.

## Current state

Files and their roles:

- `LinkClean/Shared/Services/ParameterAdvisor.swift` — the **exemplar to copy**:
  the existing Foundation Models integration (ai-A). Mirror its shape exactly.
- `LinkClean/Features/History/HistoryViewModel.swift` — owns History copy actions;
  `copyMarkdown(for:)` is the v1 surface (it uses the fetched `pageTitle`).
- `LinkCleanKit/Sources/LinkCleanCore/MarkdownFormatter.swift` — `markdownLink(title:url:)`,
  the formatter History calls. (Read it during recon to confirm the signature.)
- `LinkClean/App/AppDependencies+ViewModels.swift` — composition root that builds
  ViewModels; where the production refiner is injected.

The FM pattern to mirror (`ParameterAdvisor.swift`, abbreviated — read the full
file before copying):

```swift
import FoundationModels   // app target only; auto-links

protocol ParameterAdvising: Sendable {
    var isModelAvailable: Bool { get }
    func prewarm()
    func suggestion(among candidates: [String]) async -> ParameterSuggestion?
}

// Test/preview default — never available, never works. Injected by default in
// ViewModel inits (analogous to HistoryStore.inMemoryPreview).
struct DisabledParameterAdvisor: ParameterAdvising {
    var isModelAvailable: Bool { false }
    func prewarm() {}
    func suggestion(among candidates: [String]) async -> ParameterSuggestion? { nil }
}

struct FoundationModelsParameterAdvisor: ParameterAdvising {
    var isModelAvailable: Bool { SystemLanguageModel.default.isAvailable }
    func prewarm() {
        guard isModelAvailable else { return }
        LanguageModelSession(instructions: Self.instructions).prewarm()
    }
    private func classify(_ name: String) async -> TrackerVerdict? {
        let session = LanguageModelSession(instructions: Self.instructions)
        do {
            let response = try await session.respond(
                to: "Parameter name: \(bounded)",
                generating: TrackerVerdict.self,
                options: GenerationOptions(temperature: 0.2))
            return response.content
        } catch {
            Log.app.debug("...: \(error.localizedDescription)")   // fail soft → nil
            return nil
        }
    }
}

// @Generable MUST be `nonisolated` under MainActor-default isolation (the
// framework decodes it off-actor). Guided generation guarantees the shape.
@Generable
nonisolated struct TrackerVerdict: Equatable, Sendable {
    @Guide(description: "...") let classification: TrackerClassification
    @Guide(description: "...") let reason: String
}
```

The History Markdown copy surface as it exists today
(`HistoryViewModel.swift:134-136`):

```swift
func copyMarkdown(for entry: HistoryEntry) {
    UIPasteboard.general.string = MarkdownFormatter.markdownLink(title: entry.pageTitle, url: entry.output)
    analytics.capture(.historyEntryActioned(.markdown))
}
```

Repo conventions that apply (CLAUDE.md): `@Observable` + `@State`, never
`ObservableObject`; ViewModel inits keep test-convenience defaults; `Log.app`
+ `import OSLog`; business logic in a ViewModel method, never a View closure.

## Foundation Models — app target only (v1)

Per **SEED §4**: the model runs out-of-process, so an extension's ~120 MB limit is
*not* the blocker; the blockers are first-token **latency + process lifetime**, and
LinkClean already defers extension model calls pending a measured spike
(`docs/product/ai-features.md:44,96,181`). So this plan keeps `import FoundationModels`
in the **app target** and out of `LinkCleanExtensionUI` / `LinkCleanIntents`.
Enforced by the STOP condition + done-criterion below.

## Surfaces — main app only (v1)

| Surface | This plan? | Why |
|---|---|---|
| **Main app — History Markdown copy** (`HistoryViewModel.copyMarkdown`) | ✅ **Yes** | The only place in-app today where a *real* fetched title meets a copy format. |
| Main app — "Copy as you want" format editor | ❌ No | In-app format rendering is **preview-only** with fixed sample data (`CopyFormatEditorView.swift:45`, `CopyFormatsViewModel.swift:61` both pass `.sample`). Nothing real to refine. |
| **Action / share extension** — Pro `{title}` formats (`TemplateOutputStrategy.swift:98`) | ❌ **Deferred** | The high-value surface, but gated behind the latency/process-lifetime spike above. Not executor work. |
| App Intents | ❌ No | No title/format flow. |

So the answer to "only app / only extension / both": **v1 is the main app only**
(one surface — History Markdown). The extension is the eventual second surface,
deferred to a human spike. The `TitleRefiner` service this plan builds is shared
infrastructure both surfaces will use.

## Free vs Pro

ai-C is a **Pro** feature, applying iap §6 rule 3 — *gate addition, not operation*
(`docs/product/ai-features.md:97`).

| Capability | Free | Pro (Apple-Intelligence devices) |
|---|---|---|
| Copy a cleaned link in any format, incl. Markdown with the page title | ✅ works, **raw** title | ✅ works |
| AI title refinement | ❌ raw title, unchanged | ✅ messy title → essential title |

- **Stays free:** the *operation* — copying a formatted/Markdown link — is unchanged
  for everyone; free output is byte-identical to today (the plan asserts this).
- **Pro unlocks:** the *enhancement* — the on-device title rewrite.
- **Mechanism (Step 2):** refine only when `entitlement == .pro && refiner.isModelAvailable`,
  else return the raw `pageTitle`. **No paywall is raised at copy time** (that would gate
  the operation); refinement simply doesn't apply for free users — the upgrade prompt
  lives on the existing formats/Pro surface, not in this copy path.
- **Affected areas (SEED §3 + §6):** ai-C rides the *existing* formats Pro pitch, so
  **no new paywall benefit row and no new `PaywallTrigger`**; and **no new analytics**
  — it reuses `historyEntryActioned(.markdown)`. The only behavior change is the Step 2 gate.
- **Honesty constraint (`ai-features.md:90`):** a Pro feature that only runs on
  Apple-Intelligence hardware — any Pro/paywall copy must lead with universal value
  (depth, formats, custom rules) and list refinement as *"on supported devices"*, never
  a headline promise. (No paywall copy is in this plan's scope; bind any you add.)
- **Logged dissent (decided — do not re-open):** better *free* Markdown titles would
  strengthen the viral PKM loop, but refinement stays Pro because formats are the
  established Pro vehicle and device-gating would make *free* behavior inconsistent
  across devices.

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Kit fast lane | `cd LinkCleanKit && swift test` | all suites pass (was 266) |
| App compile + tests compile | `xcodebuild build-for-testing -project LinkClean.xcodeproj -scheme LinkCleanTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -quiet` | `EXIT: 0` (only pre-existing `ShareCardView.swift` `Text(+)` warnings) |
| App tests (best effort) | `xcodebuild test -project LinkClean.xcodeproj -scheme LinkCleanTests -only-testing:LinkCleanTests/HistoryViewModelTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'` | tests pass — **runner is flaky**; if it hangs "before establishing connection", that is infra, not your change; rely on `build-for-testing`. |

## Scope

**In scope:**
- `LinkClean/Shared/Services/TitleRefiner.swift` (create)
- `LinkClean/Features/History/HistoryViewModel.swift` (wire the refiner + entitlement into `copyMarkdown`)
- `LinkClean/App/AppDependencies+ViewModels.swift` (inject the production refiner)
- `LinkCleanTests/TitleRefinerTests.swift` (create — `DisabledTitleRefiner` behavior + the gate logic)
- `LinkCleanTests/HistoryViewModelTests.swift` (extend — Pro vs free refinement path)

**Out of scope (do NOT touch):**
- Anything under `LinkCleanKit/Sources/LinkCleanExtensionUI/` or `LinkCleanIntents/`
  — extension-side ai-C is deferred (see "Foundation Models — app target only").
- `TemplateRenderer` / `LinkTemplate` / the format presets — they already exist.
- The free *non-Pro* History Markdown output must stay byte-identical (raw title).

## Steps

### Step 1: Create the `TitleRefiner` service (mirror `ParameterAdvisor`)

Create `LinkClean/Shared/Services/TitleRefiner.swift`. Mirror `ParameterAdvisor.swift`
exactly in structure:

- `protocol TitleRefining: Sendable` with `var isModelAvailable: Bool { get }`,
  `func prewarm()`, and `func refine(_ rawTitle: String) async -> String?`
  (returns `nil` on unavailable/empty/guardrail/error — caller falls back to raw).
- `struct DisabledTitleRefiner: TitleRefining` — `isModelAvailable = false`,
  `prewarm()` no-op, `refine(_:) -> nil`. This is the ViewModel/test default.
- `struct FoundationModelsTitleRefiner: TitleRefining` — `isModelAvailable =
  SystemLanguageModel.default.isAvailable`; `prewarm()` warms a throwaway session;
  `refine` runs a fresh `LanguageModelSession(instructions:)` per call (independence),
  `generating: RefinedTitle.self`, low temperature (`0.2`), `try await
  session.respond(...)`; on any thrown error `Log.app.debug(...)` and return `nil`.
  Bound the input length (copy the `maxNameLength`/`prefix` guard idea; titles can
  be long — cap at e.g. 256 chars). If the refined title comes back empty or longer
  than the input, return `nil` (fall back to raw — a refinement should shorten/clean).
- `@Generable nonisolated struct RefinedTitle: Equatable, Sendable { @Guide(description:
  "The essential page title, with site name, marketing/SEO suffixes, prices, and
  calls-to-action removed. Keep the core subject. No quotes, no extra words.") let
  title: String }`.
- Instructions string (factual, bounded): e.g. *"You clean up a web page title for
  a reading list. Remove the site/brand name, marketing or SEO suffixes, prices,
  and calls to action. Keep the essential subject of the page. Return only the
  cleaned title, nothing else."*

**Verify**: `cd LinkCleanKit && swift test` still passes (no kit change yet — this
just confirms you didn't break the build), then the `build-for-testing` command
→ `EXIT: 0`.

### Step 2: Gate + apply refinement in `HistoryViewModel.copyMarkdown`

ai-C is **Pro**, and the free Markdown flow must keep raw titles
(`ai-features.md:97`). So refine only when the user is Pro **and** the model is
available; otherwise use the raw `pageTitle` unchanged.

- Add two dependencies to `HistoryViewModel`: `private let refiner: TitleRefining`
  (default `DisabledTitleRefiner()`) and a way to read the entitlement. Check how
  the other app ViewModels read entitlement (Grep `entitlement` in
  `LinkClean/Features/**/*ViewModel.swift` and `AppDependencies+ViewModels.swift`);
  match that mechanism (likely an injected `EntitlementsModel` or an `Entitlement`
  passed in). **If History has no existing entitlement access and adding it would
  touch more than `HistoryViewModel` + `AppDependencies+ViewModels.swift`, STOP and
  report** — do not thread entitlement through unrelated types.
- Make `copyMarkdown(for:)` `async` (the View calls it from a `Button`/task — adjust
  the call site in `HistoryCellView.swift:119` to `Task { await viewModel.copyMarkdown(for: entry) }`
  if it isn't already in an async context; match how other async VM calls are invoked there).
- New body shape:

```swift
func copyMarkdown(for entry: HistoryEntry) async {
    let title = await refinedTitle(for: entry)
    UIPasteboard.general.string = MarkdownFormatter.markdownLink(title: title, url: entry.output)
    analytics.capture(.historyEntryActioned(.markdown))
}

private func refinedTitle(for entry: HistoryEntry) async -> String? {
    guard let raw = entry.pageTitle, entitlement == .pro, refiner.isModelAvailable else {
        return entry.pageTitle   // free / no-AI / no-title → raw, unchanged
    }
    return await refiner.refine(raw) ?? raw
}
```

**Verify**: `build-for-testing` → `EXIT: 0`.

### Step 3: Inject the production refiner

In `LinkClean/App/AppDependencies+ViewModels.swift`, where the History ViewModel is
built, pass `FoundationModelsTitleRefiner()` (production) — mirror how
`FoundationModelsParameterAdvisor` is injected for `HomeViewModel`. Optionally call
`refiner.prewarm()` where the advisor is prewarmed, if a natural lifecycle hook exists
(do not invent one).

**Verify**: `build-for-testing` → `EXIT: 0`.

## Test plan

- `LinkCleanTests/TitleRefinerTests.swift` (model after `LinkCleanTests/PaywallViewModelTests.swift`
  for structure): `DisabledTitleRefiner.refine` returns `nil`; `isModelAvailable == false`.
- `LinkCleanTests/HistoryViewModelTests.swift` (extend): with a **stub refiner** that
  returns a fixed refined string, assert that a **Pro** user's `copyMarkdown` writes
  the *refined* title into the pasteboard, and a **free** user (or unavailable model)
  writes the *raw* `pageTitle`. Use `SpyAnalytics` (`LinkCleanTests/SpyAnalytics.swift`)
  and a `HistoryStore.inMemoryPreview`-style setup as the existing tests do.
- Verification: `build-for-testing` → `EXIT: 0`; run the History test filter (best
  effort given the flaky runner).

## Done criteria

ALL must hold:

- [ ] `cd LinkCleanKit && swift test` → all suites pass.
- [ ] `xcodebuild build-for-testing … -scheme LinkCleanTests …` → `EXIT: 0`.
- [ ] `grep -rn "import FoundationModels" LinkCleanKit/Sources/LinkCleanExtensionUI LinkCleanKit/Sources/LinkCleanIntents` → **no matches** (FM stayed out of the extensions).
- [ ] New `TitleRefinerTests` + extended `HistoryViewModelTests` exist and assert the Pro-vs-free path.
- [ ] No files outside the in-scope list are modified (`git status`).
- [ ] `docs/plans/README.md` status row for 001 updated.

## STOP conditions

Stop and report (do not improvise) if:

- The `ParameterAdvisor.swift` or `HistoryViewModel.copyMarkdown` excerpts above
  don't match the live code (drift since `685aff6`).
- Wiring entitlement into `HistoryViewModel` would require touching files beyond
  `HistoryViewModel.swift` + `AppDependencies+ViewModels.swift`.
- You find yourself needing to import `FoundationModels` into any `LinkCleanExtensionUI`
  or `LinkCleanIntents` file — that is the deferred extension surface, out of scope.
- `MarkdownFormatter.markdownLink` has a different signature than `(title: String?, url: String)`.

## Maintenance notes

- **The deferred extension surface is the real prize.** Before wiring ai-C into
  `TemplateOutputStrategy` (the Pro `{title}` formats in the share extension), run
  the spike in `ai-features.md:181`: measure FM first-token + total latency inside
  the share-extension process on baseline hardware (A17 Pro), confirm it stays inside
  the share budget on top of `LPMetadataProvider`'s fetch, and verify memory headroom.
  That work also needs the extension to read entitlement via the dormant App-Group
  `EntitlementStore` snapshot (`ai-features.md:96`, iap §9 rule 1). It is a separate plan.
- Reviewer scrutiny: (1) free/non-AI Markdown output is byte-identical to before;
  (2) `RefinedTitle` is `nonisolated`; (3) refinement never blocks or errors the copy
  (always falls back to raw); (4) no `FoundationModels` import crossed into the kit's
  extension/intents targets.
- A meaning-altering rewrite is the model risk — the raw title stays stored on the
  `HistoryEntry`; refinement happens only at copy time, so it is never persisted.
