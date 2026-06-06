# LinkClean AI Strategy

> **Status: proposed** — 2026-06-06. No feature below is committed to a release; sequencing in §8 is the recommendation.
> Scope: **whether, where, and how** to use AI/LLM in LinkClean — candidate features, free/Pro placement, standing constraints, sequencing. Implementation detail (sessions, prompts, migrations) is deferred to a future `docs/plans/ai-features-implementation-plan.md` when a feature is actually scheduled.
> Substrate decision up front: **Apple Foundation Models only** (on-device, iOS 26+). Cloud LLMs are ruled out permanently — §3.
> Sources: codebase audit + Apple Foundation Models research, June 2026 (§12). Aligned with [iap-strategy.md](../strategy/iap-strategy.md) ("iap §n" below) and [docs/TODO.md](../TODO.md).

---

## 1. Context (June 2026)

- **The app is 100% deterministic today.** `URLCleaner.clean(_:removing:)` filters query items against an 85-parameter catalog (`TrackingParameters.swift`, 7 categories) plus user custom parameters. No ML anywhere. That determinism is a *feature* — the core action must stay that way (§3 rule 1).
- **The brand constrains the technology.** Marketing is *"Free. No ads. No subscription. No tracking."* A cloud LLM means uploading users' URLs — effectively their browsing trail — to a server: self-refuting for a privacy app, plus per-call costs against a pay-once business model. **Apple Foundation Models** (`import FoundationModels`, iOS 26+) is the only acceptable substrate: free, offline, no API key, no data leaves the device. It also *is* the marketing line: **"On-device Apple Intelligence — your links never leave your phone."**
- **The model is small, and Apple is honest about it.** ~3B parameters, 4,096-token context window, 15 languages. Apple's guidance: excels at summarization, extraction, classification, tagging, text refinement; explicitly *"not designed to be a chatbot for general world knowledge."* Every option in §5 is a classification/refinement task by design.
- **WWDC 2026 runs June 8–12 — next week.** Foundation Models API changes are plausible. **Re-verify §2 and §4 after the keynote before building anything** (§11).

---

## 2. Platform reality: the availability stack

A Foundation Models feature works only when **all four** layers hold:

| Layer | Requirement | When it fails |
|---|---|---|
| OS | iOS 26+ (`#available(iOS 26.0, *)` — app target is iOS 18.0) | Code path simply absent |
| Hardware | Apple Intelligence-capable: iPhone 15 Pro / 15 Pro Max, all iPhone 16/17; M1+ iPad/Mac; A17 Pro iPad mini | `.unavailable(.deviceNotEligible)` → hide the feature permanently |
| User setting | Apple Intelligence enabled | `.unavailable(.appleIntelligenceNotEnabled)` → optional gentle pointer to Settings, never nag |
| Model asset | Downloaded and ready | `.unavailable(.modelNotReady)` → transient; retry silently later |

Checked at runtime via `SystemLanguageModel.default.availability`.

**Implication — the defining design constraint:** a large share of the install base will never see these features (a standard iPhone 15 is ineligible). Every AI feature must therefore be **progressive enhancement**: the app is complete without it, no UI placeholder begs for a better phone, and the free→Pro pitch never *depends* on AI being present (§7).

---

## 3. Standing constraints (the "never" list)

Extends iap §12; same permanence.

1. **Never put a model in the cleaning path.** `URLCleaner` stays rule-based: correctness-critical, instant, testable. The category's cautionary tale is the competitor *AI Link Cleaner* (iap §2): AI gimmick + usage caps + $100 lifetime → public backlash.
2. **On-device only, forever.** No cloud LLM, no AI-service dependency, no API key. If Foundation Models can't do it, the feature doesn't exist.
3. **Suggestion-only.** The model proposes; the user confirms. Nothing AI-driven ever mutates a URL, a parameter list, or history without an explicit tap.
4. **Deterministic-first.** No model where the catalog or string ops suffice (§6). A model is reached for only where *judgment* is required.
5. **Never in the action extensions (v1).** iap §9 already bans paywalls there; latency and process-lifetime concerns ban model calls too, pending the §11.3 spike. The share flow is sacred.
6. **No usage caps on AI features.** On-device inference costs nothing; metering it would be artificial scarcity (the AI Link Cleaner mistake again).
7. **Don't rebrand around "AI."** A privacy utility with intelligent touches, not an "AI app." The phrase that is safe and true: *on-device Apple Intelligence; links never leave the phone.*

---

## 4. What the model offers LinkClean

The capabilities that matter here (full research trail in §12):

- **Guided generation (`@Generable` / `@Guide`)** — constrained decoding *guarantees* output matches a declared Swift type (e.g. an `.anyOf([...])` choice). No JSON parsing, no malformed output, no retry loops. This is what makes small-model classification shippable.
- **`.contentTagging` use case** — `SystemLanguageModel(useCase: .contentTagging)`, a built-in variant tuned for tagging/classification/extraction. Purpose-built for §5-B.
- **Low-temperature classification** — `GenerationOptions(temperature: 0.2)` or greedy sampling for near-deterministic verdicts.
- **`prewarm()`** — hides first-call model-load latency when invoked on screen entry.
- **Bounded inputs** — every §5 option feeds the model tiny inputs (a param name, a page title); the 4,096-token window is a non-issue by design. Don't hardcode it anyway: `contextSize` / `tokenCount(for:)` shipped in iOS 26.4, back-deployed.
- **Enumerable failure surface** — `guardrailViolation`, `refusal`, `exceededContextWindowSize`, `unsupportedLanguageOrLocale`, `rateLimited`, `concurrentRequests`. For optional features the handling is uniform: catch → degrade to no-suggestion → never surface an error.

What it can't do: world knowledge ("is `cmpid` Adobe's parameter?" — it doesn't *know*), math, long-form, guaranteed accuracy. Prompts must lean on lexical/semantic judgment, always offer an "unsure" out, and the UX must absorb wrong answers (§3 rule 3).

---

## 5. Feature options

| # | Feature | Model task | Free/Pro | Effort | Target |
|---|---|---|---|---|---|
| **A** ⭐ | Unknown-parameter advisor | classify param name → tracking / functional / unsure | suggestion free; *acting* hits the existing custom-param gate | S | 1.2 |
| **B** | History auto-tagging | title + domain → fixed-taxonomy tag | Pro | M | 1.2/1.3 |
| **C** | Title refinement for copy formats | messy page title → clean essential title | Pro | S–M | with HTML/Title+URL |
| **D** | Natural-language history search | query → structured filters | Pro | M | 1.3+ (needs B) |
| **E** | App Intents / Shortcuts (adjacent — no model) | — | Pro (iap §6 matrix) | M | before D |

### A. Unknown-parameter advisor ⭐ (build first)

After a clean, query params can survive that are in neither the catalog nor the user's customs. Today they're silently kept. The advisor classifies the leftovers and surfaces at most one inline suggestion in Home: *"`cmpid` looks like a campaign tracker — add to custom parameters?"*

- **Why it leads:** sharpest differentiation (Clean Links knows only its list; LinkClean exercises judgment on the long tail), *and* it feeds the funnel — "add custom parameter" is already the 1.1 Pro gate (iap §6). Free users see the suggestion (education + visible intelligence); tapping it lands on the already-sanctioned locked-feature trigger (iap §9). Pro/grandfathered users get one-tap add. **No new gate is invented.**
- **Two-tier design:** tier 1 is deterministic heuristics (substring signals: `utm_`, `clid`, `camp`, `track`, `aff`, `ref`…) — works on *every* device, no model. Tier 2 is the model for the ambiguous middle, via a `@Generable` verdict (`classification` constrained to `tracking / functional / unsure`, `confidence`, a one-line reason), temperature ≈ 0.2. Only high-confidence `tracking` verdicts surface. The feature partially exists on ineligible devices and gets smarter on eligible ones — exactly §2's progressive-enhancement requirement.
- **Failure absorption:** a false positive means the user added a param that breaks a site — the existing toggle/delete escape hatches recover it (same rationale that keeps default-parameter toggles free, iap §6), and the suggestion always shows its reason. Never auto-add (§3 rule 3). Keep a small denylist of famously functional names (`q`, `id`, `page`, `v`, `t`…) the advisor never questions.
- **Where:** new `ParameterAdvisorService` protocol + heuristic impl + FM impl in `LinkClean/Shared/Services/`; surfaces in `HomeView` only — not in extensions (§3 rule 5).

### B. History auto-tagging (Pro)

Background-classify each `HistoryEntry` into a fixed taxonomy — `article / shopping / video / social / docs / dev / other` — from `pageTitle` + host, using the purpose-built `.contentTagging` model. Persist as a new optional field (additive SwiftData migration); History gains filter chips.

- **Why:** this is the productivity-positioning feature (iap §1: win as a *link productivity tool*). Pro's pitch is unlimited *searchable* depth; tags make depth *organized*. Lands behind the existing entitlement per the "all future Pro features" promise (iap §8, Expand).
- **Mechanics:** lazy batch pass mirroring the existing `metadataFetchAttempted` pattern; fixed taxonomy enforced by an `.anyOf` guide (no free-form tags, no taxonomy drift); skip entries with no title; non-English titles tag normally within the 15 supported languages, else fall back to `other`/untagged.
- **The honesty problem:** a Pro feature that only works on Apple-Intelligence devices. Paywall copy must lead with universal Pro value (depth, formats, custom rules) and list tagging as *"on supported devices"* — never as a headline promise (§7).

### C. Title refinement for copy formats (Pro, ships with the formats feature)

PKM users paste `"Product Name | Site – 50% OFF Buy Now!"` into Obsidian. A refinement pass rewrites to the essential title before formatting as Markdown/HTML/Title+URL. Text refinement is squarely the model's strength.

- **Placement decision pending a spike (§11.3):** the natural value moment is inside `LinkCleanMarkdownAction` at share time, but extension process lifetime and first-token latency may make that hostile (`LPMetadataProvider`'s network fetch already dominates the flow; whether ~1s of added inference is acceptable needs measuring). v1 fallback: refine in-app only (history titles, and formats invoked from Home). If it later goes extension-side, it becomes the first real user of the dormant `EntitlementStore` App Group snapshot (iap §9, rule 1's consequence note).
- **Gating:** Pro, bundled with the HTML/Title+URL formats work — "gate addition, not operation" (iap §6 rule 3). The free Markdown flow keeps today's raw titles, untouched. *Dissent logged:* better free Markdown titles would strengthen the viral PKM loop; rejected for now because the formats feature is the established Pro vehicle, and FM device-gating would make *free* behavior inconsistent across devices.
- **Risks:** meaning-altering rewrites (always keep the original stored; refine at display/copy time), guardrail false positives on provocative headlines (catch → use raw title; iOS 26.1's permissive-content-transformations guardrail option exists if it becomes chronic).

### D. Natural-language history search (Pro, later)

"shopping links from last week" → `@Generable` filter struct (`dateRange?`, `tags?`, `domain?`, `textQuery?`) → deterministic SwiftData predicate. The model translates intent; the query itself stays exact — no hallucinated results possible. Needs B's tags to be worth building; regular search stays the default UX (and stays free per iap §6). 1.3+ at the earliest.

### E. Adjacent, not a model feature: App Intents / Shortcuts

Already Pro-when-built in the iap §6 matrix. Listed because AI-strategy conversations conflate it: App Intents is what makes LinkClean visible to Siri/Shortcuts/Apple Intelligence going forward, it's fully deterministic, and it should ship *before* D. No Foundation Models involvement.

---

## 6. What NOT to build with AI (anti-options)

Each considered and rejected — §3 rule 4 applied:

| Idea | Why not | Do instead |
|---|---|---|
| "What was removed & why" explanations | `TrackingParameters` already carries display names + 7 categories | Deterministic copy: "Removed 2 UTM and 1 ad-click parameter" — free, instant, always right |
| Fallback titles from URL slugs | `/2026/06/why-swift-rocks` → de-slugify + capitalize | String transforms |
| Privacy "risk scores" | Invented numbers from a 3B model in a privacy app = trust liability; the model has no real risk knowledge | Show counts of removed params — real data |
| Chat assistant | Model explicitly not built for open-ended chat; a utility app needs none | — |
| Model-generated catalog updates | Correctness-critical (§3 rule 1); model lacks vendor-param world knowledge | Curated catalog updates in app releases, sourced from public tracker lists and user reports |

---

## 7. Free/Pro placement

Applying iap §6's three rules (never gate the core action; never claw back; gate addition, not operation):

| Surface | Free | Pro | Note |
|---|---|---|---|
| A — suggestion shown (heuristic + FM tiers) | ✅ | — | Education + differentiation; visible intelligence sells Pro indirectly |
| A — acting on it (add custom param) | ❌ (existing 1.1 gate) | ✅ | No new gate; reuses iap §9's locked-feature trigger |
| B — history tags + filter chips | ❌ | ✅ | "On supported devices" phrasing mandatory |
| C — refined titles in formats | ❌ | ✅ | Bundled with HTML/Title+URL; free Markdown untouched |
| D — NL search | ❌ | ✅ | Regular search stays free (iap §6) |

**Paywall copy rule (extends iap §9):** AI-dependent features never headline the paywall. Lead with depth/formats/rules (universal); AI features appear as *"Plus, on supported devices: …"*. Headlining device-gated capability invites refunds and 1★ "doesn't work on my phone" reviews.

---

## 8. Sequencing

| Phase | Version | AI scope |
|---|---|---|
| Ship 1.0 | 1.0 | **None.** TODO scope is locked (screenshots, onboarding, metadata); AI must not delay launch. |
| WWDC gate | — | June 8–12, 2026: re-verify §2/§4 against announcements; revise this doc if the API moves. |
| Monetize | 1.1 | **None.** IAP-only and timeboxed (iap §8). No feature scope rides along — including this. |
| First AI beat | 1.2 | **A** (advisor, both tiers), plus C's latency spike in parallel. Marketing beat: the on-device-intelligence update. |
| Second | 1.2/1.3 | **B** (tagging); **C** ships with the formats feature. |
| Later | 1.3+ | **E**, then **D**. |

No deployment-target raise at any point: the app stays iOS 18; AI compiles behind `#available(iOS 26.0, *)`.

---

## 9. Evaluation signals

Extends the TelemetryDeck plan ([docs/plans/analytics.md](../plans/analytics.md)). **Privacy rule: no URLs, no param values, no param names in analytics** — categories, booleans, counts only.

- **A:** `paramSuggestionShown / Accepted / Dismissed` (+ tier: heuristic vs model). Healthy = acceptance meaningfully above zero, dismissals not dominating. `suggestionShown → paywallShown(customParams)` joins the iap §11 funnel.
- **B:** share of history entries successfully tagged; filter-chip usage.
- **Latency guardrail:** a suggestion lands within ~2s of a clean (post-`prewarm()`) or is dropped silently for that clean — never a spinner.
- **Kill criterion:** if A's acceptance rate is negligible after a full release cycle, demote to heuristics-only and reclaim the maintenance surface.

---

## 10. Architecture notes (for the future plan doc)

- **Protocols + fakes:** each feature behind a service protocol (`ParameterAdvisorService`, …) in `LinkClean/Shared/Services/` per the existing `URLCleaningService` pattern; live impls are `@available(iOS 26.0, *)`; tests use deterministic fakes (Swift Testing) — never assert against the live model in CI.
- **DTOs:** `@Generable` structs, feature-scoped; `.anyOf` guides for every classification.
- **Availability:** one small `@Observable` helper mapping §2's table; checked at screen entry; `prewarm()` only when available *and* the screen can use the feature.
- **Errors:** uniform catch-and-degrade (§4). `concurrentRequests` avoided via one session per service + `isResponding` check; `rateLimited` skips the batch round (B).
- **Concurrency:** project default isolation is MainActor; B's batch tagging runs `nonisolated`. If anything lands in LinkCleanKit, mind the kit's localization constraint (no `manual` xcstrings entries — CLAUDE.md).
- **SwiftData:** B adds an optional field to `HistoryEntry` (additive, lightweight migration) plus a `tagAttempted`-style flag mirroring `metadataFetchAttempted`.

---

## 11. Open questions (resolve before/at each build)

1. **WWDC 2026 (June 8–12):** Foundation Models API changes, new use cases, context-window or eligibility changes → revise §2/§4/§5.
2. **Extension deployment targets:** pbxproj shows the extensions/tests at iOS 26.0 while the app is 18.0 — intended, or leftover? Affects whether extension-side code ever needs `#available`, and what 1.0 actually ships with.
3. **C's extension-side spike:** measure FM first-token + total latency inside `LinkCleanMarkdownAction` on baseline hardware (A17 Pro), and verify extension memory headroom (inference is system-managed, but verify, don't assume).
4. **`.contentTagging` vs base model for B:** prototype whether the tagging use case respects a strict `.anyOf` taxonomy, or whether base model + guided generation behaves better.
5. **Localization interaction:** 1.0 ships unlocalized; when translations land, gate AI features on the model's `supportedLanguages` (15 languages; `unsupportedLanguageOrLocale` otherwise).

---

## 12. Sources

- Apple — Foundation Models framework: <https://developer.apple.com/documentation/foundationmodels>
- Apple — `SystemLanguageModel` (availability, use cases): <https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel>
- Apple — Generating content and performing tasks: <https://developer.apple.com/documentation/FoundationModels/generating-content-and-performing-tasks-with-foundation-models>
- Apple — `GenerationGuide`: <https://developer.apple.com/documentation/foundationmodels/generationguide> · `Tool`: <https://developer.apple.com/documentation/foundationmodels/tool>
- WWDC25 #301 — Deep dive into Foundation Models: <https://developer.apple.com/videos/play/wwdc2025/301/>
- Apple ML Research — 2025 foundation-model updates (3B specs, 15 languages, "not… a chatbot for general world knowledge"): <https://machinelearning.apple.com/research/apple-foundation-models-2025-updates>
- InfoQ — iOS 26.4 `contextSize` / `tokenCount(for:)`, window stays 4,096: <https://www.infoq.com/news/2026/03/apple-foundation-models-context/>
- zats.io — context-window management patterns: <https://zats.io/blog/making-the-most-of-apple-foundation-models-context-window/>
- Create with Swift — framework exploration / API patterns: <https://www.createwithswift.com/exploring-the-foundation-models-framework/>
- Graceful fallback when Apple Intelligence is unavailable: <https://dev.to/arshtechpro/how-to-fall-back-gracefully-when-apple-intelligence-isnt-available-48j>
- TechCrunch — WWDC 2026 dates (June 8–12): <https://techcrunch.com/2026/03/23/apple-wwdc-june-8-12-ai-advancements-siri-developers-conference/>
