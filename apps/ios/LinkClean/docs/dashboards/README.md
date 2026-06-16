# Dashboards

TelemetryDeck dashboards for LinkClean. Import-only via the TelemetryDeck UI — the JSON files in this directory are the source of truth. Every signal that backs them is a case on the typed `AnalyticsEvent` enum in `LinkCleanKit/Sources/LinkCleanCore/AnalyticsEvent.swift`, so the dashboard set drifts only when that enum drifts.

## The three boards

Each one answers a different question. Open them together when you want a cross-board read; otherwise pick the one that maps to the decision.

| Board | Question it answers | When to open |
|---|---|---|
| [`Dashboard-LinkClean-Core-Usage.json`](Dashboard-LinkClean-Core-Usage.json) | Is the core loop healthy? | Weekly health check; before/after any change that touches the clean → export path |
| [`Dashboard-LinkClean-Growth-Surfaces.json`](Dashboard-LinkClean-Growth-Surfaces.json) | Did the 1.1 bets land? | After any 1.1 feature ships; deciding what to invest in for 1.2 |
| [`Dashboard-LinkClean-Monetization.json`](Dashboard-LinkClean-Monetization.json) | Does the IAP funnel convert? | Pricing or paywall-copy changes; gate-trigger A/Bs; weekly revenue health (with App Store Connect open alongside) |

## The default parameters

Two parameters ride on **every** signal (set in `TelemetryDeckAnalytics.start`):

- **`tier`** = `free` / `pro`. Reads the live `EntitlementStore` per signal — flips to `pro` the moment a purchase resolves. Cannot be backfilled. Slice any insight on any board by `tier` for the Pro-vs-free behavioral read.
- **`surface`** = `app` / `action` / `copyAction` / `intent`. The process-level surface. Separates the two share extensions and the App Intents process from the app process. (Logical splits inside one process — `intentSurface=shortcut|clipboard`, `entryPoint=toolbar|cta` — ride on their own signal-specific keys to avoid collision with `surface`.)

## The north-star export set

A "clean delivered" — deduped per distinct output. Seven events:

```
Home.URL.copied         (app)
Home.URL.shared         (app)
Action.Clean.succeeded  (Clean ext)
Action.Format.succeeded (Copy-format ext)
Intent.Clean.succeeded  (App Intents — clipboard write IS the delivery)
QR.Result.actioned      (QR scan exports — copy/share/open off the result sheet)
QR.Code.generated       (QR generate exports — shared QR image)
```

Deliberately **excluded**: `Home.URL.cleaned` and `QR.Scan.succeeded` are *cleans*, not exports (curiosity until acted on). `History.Entry.actioned` is a re-export of a past clean — tracked separately (Core-Usage insight 23) to avoid double-counting.

## Thresholds worth knowing

Use these as starting tripwires, not gospel. Move them as the product matures.

**Core-Usage**
- Activation ≥ 70% of new installs reach a first export (else the onboarding-to-Home path is broken).
- Exports per active user per week ≥ 3 = healthy loop (insight 8). Below 2 = curiosity, not habit.
- Catalog-gap insight 14: any tracker in the top 3 with a long tail = promote to defaults (precedent: `utm_id`, `gbraid`, `wbraid`, etc. — see `memory/catalog-default-false-positives.md`).
- Review-gate `low` bucket > 30% of ratings = address the negative-rating drivers before driving more review prompts.

**Growth-Surfaces (1.1 bets)**
- Unwrap rate ≥ 5% of cleans (E1) = the embedded-destination unwrapper earns its complexity.
- App Intents share ≥ 10% of weekly exports (S1) = the OS-surface bet landed.
- QR scan → action ≥ 60% (insight 7) = the scan-result sheet isn't a leak.
- Stats.Card share rate ≥ 10% per *populated* Stats view (V3) = the viral loop is functioning.
- Advisor accept rate ≥ 30% on any tier (ai-A) = it earns its sheet space.
- Preset-vs-custom flipping toward custom = the strongest signal that Pro customization will sell.

**Monetization**
- Paywall click-through ≥ 8% (overall, unique users) = the paywall copy lands. Per-trigger rate is the more actionable cut (insight 2).
- `pending` share of failures > 20% (insight 6) = lots of Ask-to-Buy / SCA — the immediate-completion rate (insight 5) understates true conversion. Cross-check ASC.
- Paid share of WAU is the long-tail metric — set the target after the first 30 days of post-1.1 data, not before.

## Source-of-truth split

- **TelemetryDeck (these boards)** owns the **behavioral** funnel — what users do, which gates fire, which surface they reach from.
- **App Store Connect** owns **revenue, units sold, refunds, and the cross-device/Ask-to-Buy completion path**. `Pro.Purchase.completed` here counts only synchronous in-sheet completions, by design (`AnalyticsEvent.swift` line 199 — re-emitting from `Transaction.updates` would double-fire on cross-device/reinstall syncs).

Never join the two at user grain. ASC's billing identity and TelemetryDeck's `clientUser` are deliberately independent. Join at `tier` / day / trigger.

## Open 1.1 questions

These are the gaps in the current insight set — track them, decide whether to instrument later.

1. **Hardware-availability split for the AI advisor (ai-A).** The model tier only runs on Apple-Intelligence-capable hardware; the heuristic/reference tiers run everywhere. No hardware-availability signal ships today, so insight 14/15 mix these populations. Watch tier-share drift over time as iOS 26+ Apple-Intelligence install base grows.
2. **Control Center vs widget intent split.** Both run `CleanClipboardIntent` and both report `intentSurface=clipboard`. Splitting requires a per-surface intent parameter (which would clutter the Shortcuts editor). Defer until the data shape demands it (`AnalyticsEvent.swift` line 247).
3. **`export` / `sync` paywall triggers.** Declared in the enum (`PaywallTrigger.export`, `.sync`) for later surfaces and currently ship UNFIRED. The Monetization board will not show those values until a future feature raises one.
4. **Fragment-cleaning impact (E2) has no dedicated signal.** Fragment-borne tracker removals fold into the `removedCount` on clean events (`URLCleaner.swift` line 148). Today we only read E2 indirectly via the `Settings.TextFragments.toggled` opt-out rate (Growth-Surfaces insight 2). If we ever want to size the fragment-cleaning impact directly, the signal has to be added.

## Keeping the boards in sync with the code

When you add or rename an `AnalyticsEvent` case:

1. Update the matching `type` selectors in every board that references it (grep the dashboard JSONs for the old signal name).
2. Bump the affected board's `_exportMetadata.version` and refresh `exportedAt`.
3. Update the `dynamicFields` hints if the parameter shape changed.
4. Re-import the JSON in the TelemetryDeck UI.

The dashboards are durable — most edits are taxonomy follow-ups, not rebuilds. The two rewrites so far: v1→v2 of Core-Usage and Monetization (2026-06-16, post-1.1.0), after the `Action.Markdown.*` → `Action.Format.*` rename and the `Pro.Purchase.*` IAP-funnel completion.
