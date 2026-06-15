# Feature Plan Seed — LinkClean

Start every feature plan from this checklist. It sits **on top of** the generic
template (`.claude/skills/improve/references/plan-template.md`) and captures the
LinkClean-specific decisions a plan must make explicit. Answer all eight — "N/A"
is a valid answer; silence isn't.

1. **Strategy fit.** Which wedge does it deepen — *formats / on-device AI /
   history-depth*? The free competitor (Clean Links) already gives away cleaning,
   redirect-unwrap, short-link expansion, Safari auto-strip, and lite sync, so
   those are catch-up / **weak Pro gates**, not differentiation
   (`docs/strategy/competitor-clean-links.md` §6). North star = exports per active
   user per week.

2. **Surfaces — only app / only extension / both?** Enumerate against: Home (app),
   History, QR, Action/Share extensions (`LinkCleanExtensionUI`), App Intents
   (`LinkCleanIntents`). Shared engine seam = `CleaningService` (app + both
   extensions + intents). **Extensions/Intents are short-lived with tight
   time/memory budgets** → network or model calls there need a measured latency
   spike first; default **app-first, extension deferred**.

3. **Free vs Pro.** Apply iap §6 rule 3 — *gate addition/accumulation, never the
   operation*; never claw back; every gated thing **free-to-run**; no extension
   paywalls; no subscription; one entitlement, ≤ $5.99. Give a **Free | Pro table**
   + the exact gate site (paywall trigger) + where the upgrade prompt lives.
   **If it's a Pro feature, sell it — a gate with no shop window is a silent
   feature. Update every affected area:**
   - **Paywall benefits** — add/refresh a benefit row (`PaywallView.benefits` +
     `paywall.benefit.*` in **all locales** en/ja/de, with translator comments).
   - **Trigger + contextual header** — add an `AnalyticsEvent.PaywallTrigger` case
     and a per-trigger header (`PaywallView.headerTitle`/`headerIcon`) for a new gate.
   - **Keep the "future Pro feature" row honest** — don't pitch a now-shipped
     feature as still forthcoming.
   - **Per-gate analytics** — the trigger flows through `paywallShown(trigger:)` →
     `Pro.Purchase.*(trigger:)` so conversion is sliceable by gate.
   - **Device-gated (on-device AI)** — list as *"on supported devices"*, never a
     headline promise.

4. **Foundation Models? (only if the feature uses AI.)** Gate on
   `SystemLanguageModel.default.isAvailable`; degrade soft to `nil` (progressive
   enhancement, never an error); `@Generable` types are `nonisolated` (MainActor
   default). Mirror `ParameterAdvisor.swift`. **Available in action extensions?
   Technically yes** — the model is OS-managed / out-of-process, so the extension's
   ~120 MB memory limit is **not** the blocker; the blockers are first-token
   latency + process lifetime → **spike before adopting extension-side**. Keep
   `import FoundationModels` in the app target and out of the kit's
   extension/intents targets until that spike passes.

5. **Privacy & determinism.** On-device by default; the core clean stays
   deterministic and offline. Any network egress is **opt-in, off by default,
   honest copy, never logged**. No PII in analytics — closed enums / bucketed
   counts / finite catalog names only.

6. **Analytics.** Every new surface or user action gets a typed `AnalyticsEvent`
   case (`Feature.Subject.verbPast`, bucketed `[String:String]`, no PII): add the
   case + both switches (`signalName` + `parameters`) + a test — the
   analytics-audit pattern. Emit the shared realized-clean tail via
   `RealizedCleanRecorder` where a clean lands.

7. **Architecture fit.** Match the closest existing pattern (CLAUDE.md):
   `@Observable` + `@State` (never `ObservableObject`); the ViewModel owns logic,
   the View calls a method; deps via the composition root (`AppDependencies`);
   domain types ship identifiers, not copy (localized via generated symbols). New
   shared code goes to the right kit layer (Core pure → Data → ExtensionUI / Intents
   / Analytics).

8. **Verification.** Put testable logic in Core/Data so it runs the fast lane
   (`cd LinkCleanKit && swift test`, macOS, ~1s). Compile gate =
   `xcodebuild build-for-testing -scheme LinkCleanTests …` — the app-test sim
   runner is **flaky**, so don't read a "runner hung" as a failure. Every plan ends
   with machine-checkable done criteria + STOP-on-drift.

---

The **technical implementation** itself (Current-state excerpts, ordered Steps,
test plan) lives in the generic template. This seed only ensures the eight
LinkClean decisions above are *decided in writing*, not assumed.
