---
name: analytics-audit
description: >-
  Audit whether LinkClean is measuring the right things to drive product decisions. LinkClean has exactly two data sources — the on-device iOS event layer (TelemetryDeck, via the typed `AnalyticsEvent` enum in LinkCleanKit) and App Store Connect (installs / revenue). For each product question — activation (first clean), the copy/export north-star, Share-extension adoption, customization depth (custom parameters), catalog-gap coverage, retention, and IAP readiness (planned 1.1.0) — it checks which source holds the answer, whether we capture it, and how to read it. It EDITS only the iOS event layer (`AnalyticsEvent.swift` + call sites + `AnalyticsEventTests.swift`), with zero PII and no taxonomy drift; App Store Connect it routes to the dashboard / the app-store-optimization skill. Use whenever the user wants to review or improve analytics / measurement, asks "are we tracking the right things", "what should we track", "what does our data tell us", "how do we measure X", "where does that data live", "add an event for X", wants to instrument a flow, or is prepping metrics for a product or IAP decision. Reach for it even on a vague "our analytics feels thin" or "can we even answer that with our data". TRIGGER on "audit analytics", "review our events/metrics", "what should we be tracking", "how do we measure", "add an analytics event", "instrument onboarding/the share extension", "are we measuring the right things", "product-strategy metrics", "what data do we have for X". For App Store listing/ASO it hands off to app-store-optimization; the event/privacy plan itself lives in `docs/plans/analytics.md`.
---

# Analytics audit

Decide whether LinkClean's measurement earns its keep: for every product question we care about, can we answer it, *which source holds the answer*, and is what we capture clean and gap-free. This skill is **propose-then-implement** — it produces a prioritized audit, and on your go-ahead it edits the one layer it owns (the iOS event layer in LinkCleanKit) and re-runs the gates. App Store Connect it recommends and routes; it doesn't edit it.

## The mental model — read this first; the rules below are consequences of it

**Analytics exists to change decisions, not to collect data.** The test for any event, property, or metric is one question: *what would we do differently based on it?* A signal no decision reads is pure cost — cardinality, review burden, a false sense of coverage. So the audit is never "track more"; it's "measure what moves a decision, drop what doesn't, and close the gaps where a decision we care about is invisible."

**LinkClean's signal lives in exactly two places — and only one is this skill's to edit.** LinkClean is a serverless, on-device app: there is no backend, no Langfuse, no Cloudflare, no LLM cost to track. Behavior lives in **TelemetryDeck** (the iOS event layer — the only thing this skill edits); installs / conversion / revenue live in **App Store Connect**. That's the whole map. Don't invent sources LinkClean doesn't have.

**The iOS event layer is a *typed taxonomy*, not free-form `signal()` calls.** Every signal the app or an action extension can emit is a `case` on `enum AnalyticsEvent` (in LinkCleanKit), which owns its own `signalName` and bucketed `[String:String]` `parameters`. Call sites emit via `analytics.capture(.someEvent(...))` against the `AnalyticsService` protocol; the single conformer `TelemetryDeckAnalytics` is the *only* type that imports the SDK. So the enum **is** the behavior truth — you can't invent a name or a parameter key at a call site.

**Two invariants are sacred for the layer we edit:**
1. **Single source of truth.** Every iOS signal is a case on `AnalyticsEvent`. No call site constructs a signal name or parameter dictionary; no file outside `TelemetryDeckAnalytics.swift` touches the TelemetryDeck SDK.
2. **No PII, no user-authored content.** Parameters are closed enums, bucketed counts, booleans, and finite parameter *names* — either default-catalog ids or names from the bundled `ReferenceParameterCatalog`, both finite and public. **Never** a URL, host, query string, search text, page title, or a user's custom-parameter name. A free-form string is both a privacy breach and a cardinality bomb — the privacy rule and the cardinality rule are the same rule (`docs/plans/analytics.md` §3; `docs/plans/parameter-telemetry.md`).

## The data-source map

| Source | What it answers | Retrieve via | Detail / owner |
| --- | --- | --- | --- |
| **TelemetryDeck** (iOS events) | in-app + extension behavior: activation, the copy/export north-star, share-extension adoption, customization depth, catalog-gap coverage, retention | **dashboard** (free plan has no query API). `AnalyticsEvent.swift` is the source of truth for *what's emitted* | `docs/plans/analytics.md` (§5 naming, §6 main-app taxonomy, §7 extensions, §10 metrics→decisions); `docs/plans/parameter-telemetry.md` (catalog-gap Tier 0/1) |
| **App Store Connect** | installs / sessions / crashes today; conversion / retention / proceeds once IAP ships (1.1.0) | **dashboard** — App Analytics (+ Subscriptions/Sales once IAP is live) | the `app-store-optimization` skill |

There is no third source. If a question can't be answered from these two, the answer is usually "add a bounded event to the iOS layer," not "stand up new infrastructure."

## The funnel is the spine

| Stage | Decision | Behavior signal (TelemetryDeck — we edit) | Truth signal (other) |
| --- | --- | --- | --- |
| Install / launch | reach, MAU | (App Store Connect installs) | **ASC** App Analytics |
| Onboarding | activation; does the guide land | `Onboarding.Flow.completed/skipped`, `Onboarding.ExtensionGuide.shown` | — |
| First clean | activation (core value delivered) | `Home.URL.cleaned` (`source`, `changed`, counts, `removedKinds`) | — |
| **Export (north-star)** | is cleaning *used*, not just seen | `Home.URL.copied` (`changed`); `History.Entry.actioned` | — |
| Share-extension adoption | is the share sheet the real surface | `Action.Clean.succeeded/failed`, `Action.Markdown.succeeded/failed` | — |
| Customization depth | is the top premium candidate wanted | `Parameters.Custom.shown` → `Parameters.Custom.added/Deleted`; `Parameters.Default.toggled`; `Settings.*` | — |
| Catalog-gap coverage | which trackers should we add to the default catalog | `leftoverCount` / `referenceMatchCount` / `removedKinds` on cleans; `Parameters.Reference.observed` | — |
| Retention | repeat use | `History.Screen.shown` (`entryCount` bucket), `History.Search.used` | **ASC** retention |
| Monetization (1.1.0) | paywall pull → conversion | *(future)* `Paywall.*` / `Purchase.*` | **ASC** Subscriptions / RevenueCat |

Two funnels are distinctively LinkClean and worth protecting:
- **The catalog-gap loop** (`docs/plans/parameter-telemetry.md`): leftover/reference signals tell you *which tracking parameters the default catalog is missing* — a direct, recurring product decision (what to add to the catalog) that no other app's analytics has. Keep it bounded to finite catalog ids; never let a raw leftover key leak.
- **Custom parameters** is the leading IAP candidate. `Parameters.Custom.shown` vs `…added` separates discovery from value: a healthy view-rate with a low add-rate is a value problem, not a discovery one (`docs/plans/analytics.md` §6/§10).

## Step 1 — Gather

Run the gatherer (prints the declared taxonomy, the wire signal names, every call site, coverage, the SDK-boundary invariant, and a PII smell test):

```bash
bash .claude/skills/analytics-audit/scripts/gather-analytics-signals.sh
```

Then read the plan: **`docs/plans/analytics.md`** (goals, privacy, naming, the event taxonomy, metrics→decisions) and **`docs/plans/parameter-telemetry.md`** (the catalog-gap Tier 0/1 signals). Treat the code as authoritative where the plan and the code disagree — `AnalyticsEvent.swift` is the contract.

## Step 2 — Map every product question to a decision *and a source*

Build the table: the product question, the decision it informs, which source answers it, the retrieval path (TelemetryDeck dashboard vs ASC), and a verdict. A row whose source we don't currently emit is a gap → step 3.

| Question | Decision | Source | Retrieve | Verdict |
| --- | --- | --- | --- | --- |
| Do people actually export a cleaned link? | is the core loop delivering | TelemetryDeck | dashboard | keep (`Home.URL.copied`) |
| Is the share extension the real surface? | where to invest UX | TelemetryDeck | dashboard | keep (`Action.*`) |
| Which trackers is the catalog missing? | what to add to the default catalog | TelemetryDeck | dashboard | keep (catalog-gap signals) |
| Do customers want custom parameters enough to pay? | IAP scoping | TelemetryDeck × ASC | dashboard | gap until `Purchase.*` exists |
| … | … | … | … | keep / enrich / drop |

## Step 3 — Walk the funnel for gaps

For each transition ask *can we see it, and where?* A gap is: **(a)** a behavior event missing in the iOS layer; **(b)** a metric that needs ASC (route it, don't fake it in-app); or **(c)** a decision we care about that no current signal reads. Name the decision and the cardinality/effort cost for each — never propose a vanity signal.

The standing, primary gap: **monetization.** IAP is planned for **1.1.0** with RevenueCat × TelemetryDeck (`docs/plans/analytics.md` §9; `docs/plans/iap-implementation-plan.md`). The *behavior* events (`Paywall.shown`, `Purchase.attempt/succeeded/failed/restore`) live in the iOS layer we edit and are worth pre-wiring **before** StoreKit so conversion is measurable from day one — while the refund-reconciled *truth* lives in App Store Connect. Both halves belong in the recommendation. Other candidates (each only if a decision rides on it): onboarding step drop-off direction, History export-path mix, auto-paste annoyance rate (`Home.Clipboard.invalidPasted` already exists — is anything reading it?).

## Step 4 — Check the invariants

The gatherer checks the mechanical ones; you reconcile the rest:
- **[script] SDK boundary** — no `import TelemetryDeck` / `TelemetryDeck.` outside `TelemetryDeckAnalytics.swift`. Must be empty.
- **[script] PII smell test** — no parameter keyed like a URL/host/query/title/search/name; no `String`-typed associated value other than the finite-catalog `parameter`.
- **[you] Taxonomy ↔ call sites consistent** — every `AnalyticsEvent` case has ≥1 call site (the script prints coverage); every case appears in both the `signalName` and `parameters` switches (the compiler enforces exhaustiveness, but a *wrong* mapping won't be caught — eyeball them).
- **[you] Every value is bounded** — closed enum `rawValue`, a `Bucket.*` string, a stringified `Bool`, or a finite catalog id. No raw `Int`/`Bool` in the dictionary (params are `[String:String]`).
- **[you] Extensions stay parity-correct** — the action extensions emit `Action.*` through the same typed layer; confirm a new event that should fire from an extension actually does (both `LinkCleanAction` and `LinkCleanMarkdownAction`).

## Step 5 — Propose (prioritized)

One prioritized table: `add | enrich | drop | route`, the **decision it unlocks**, the **source** it touches, the call site(s) if it's the iOS layer, a cardinality/effort note, and a priority. Lead with the highest-leverage item — for a pre-IAP app heading toward 1.1.0, that's almost always the monetization funnel (the iOS `Purchase.*` events *plus* the ASC reports to read them against). Mark each item **iOS-layer (we implement)** or **ASC (we route)**. Stop here and get the user's pick before editing.

## Step 6 — Implement on approval (iOS layer only; route ASC)

This skill edits **only** the iOS event layer. For each approved iOS-layer change, match the existing shape in `AnalyticsEvent.swift`:
- **Add a `case`** with a doc-comment stating the *decision the event serves* (every existing case has one — that's the bar), closed-enum / bucketed / boolean associated values only.
- **Extend both switches in the same edit** — `signalName` (a `Feature.Subject.verbPast` string, ≤ 3 dotted levels, per `docs/plans/analytics.md` §5) and `parameters` (stringify everything: `Self.string(bool)`, `Bucket.xxx(int)`, `enum.rawValue`). Add a new `Bucket` helper rather than emitting a raw count.
- **Wire the call site(s)** via `analytics.capture(.newEvent(...))` — and the extension path too if it should fire there.
- **Add a test** to `AnalyticsEventTests.swift` asserting the new case's `signalName` and `parameters` (mirror the existing per-event assertions).
- **Run the gates** — build, then the LinkCleanKit package tests from `LinkCleanKit/`: `xcodebuild test -scheme LinkCleanKit -destination 'platform=iOS Simulator,OS=26.4,name=iPhone 17'` (app-target tests run via the `LinkCleanTests` scheme). Update `docs/plans/analytics.md` so the plan and the code move together.

For approved **ASC** changes, route — don't edit here: a listing/ASO metric → `app-store-optimization`; an install/retention/conversion number → the App Store Connect dashboard. Recommend and hand off.

## LinkClean-specific sharp edges

- **Params are `[String:String]`.** Stringify everything; a raw `Int`/`Bool` in the dictionary breaks the pattern. Numerics go through `Bucket` (e.g. `removedCount` is exact 0–4 then `"5+"`; `historySize` is `"0"|"1-9"|"10-49"|"50+"`).
- **High cardinality is the silent cost.** `source`, `removedKinds` (finite catalog ids), and catalog `parameter` names are bounded and fine; a URL, host, query string, page title, search text, or a user's *custom* parameter name is both a PII breach and a dashboard-wrecking cardinality bomb. Custom-parameter events send only the **bucketed total count**, never the name.
- **`removedKinds` is finite by construction** — sorted catalog ids joined with `,` (or `"none"`). It's safe *because* it can only contain ids from `TrackingParameterCatalog`. Don't widen it to arbitrary keys.
- **Catalog-gap signals are the point, not noise** — `leftoverCount`, `referenceMatchCount`, and `Parameters.Reference.observed` exist to answer "what should the default catalog add next" (`parameter-telemetry.md` Tier 0/1). Don't "simplify" them away; they're a load-bearing product loop.
- **The extension path is lighter by design** — extensions emit `Action.*` and initialize the SDK in `viewDidLoad`; they don't have History/Settings context. Not a gap.
- **One shared anonymous user id** across the app + both extensions (App-Group `UserDefaults`, salted+hashed client-side) — without it the app and each extension would count as separate users and activation would be unmeasurable (`analytics.md` §4). Don't break that when touching the sink.
- **Never propose a signal you can't name a decision for.** Cardinality and clutter beat "might be nice someday" every time.

## Reference: where things live

- **The iOS layer (what we edit):** `LinkCleanKit/Sources/LinkCleanKit/AnalyticsEvent.swift` (the taxonomy: `signalName` + bucketed `parameters`, param enums `CleanSource`/`EntryAction`/`GuideSource`/`FailureReason`/`TitleSource`, and the `Bucket` helpers) · `AnalyticsService.swift` (the `capture(_:)` protocol) · `TelemetryDeckAnalytics.swift` (the only SDK-touching type) · tests in `LinkCleanKit/Tests/LinkCleanKitTests/AnalyticsEventTests.swift`. Call sites: `Features/**/*ViewModel.swift` in the app, plus `LinkCleanAction/` and `LinkCleanMarkdownAction/`.
- **The plans (audit against these):** `docs/plans/analytics.md` (goals, privacy §3, naming §5, taxonomy §6–§7, metrics→decisions §10, IAP analytics §9) · `docs/plans/parameter-telemetry.md` (catalog-gap Tier 0/1) · `docs/plans/iap-implementation-plan.md` (the 1.1.0 monetization plan the purchase events serve).
- **Dashboards (where the rest lives):** TelemetryDeck (Insights / Funnels — free plan, dashboard only) · App Store Connect (App Analytics; Subscriptions/Sales once IAP ships).
- **Handoffs:** App Store listing / ASO → the `app-store-optimization` skill; per-version "What's New" → the `release-notes` skill; evergreen listing copy → the `asc-metadata` skill.
