# LinkClean — KPIs & Unit Economics

> **Status: draft — 2026-06-09.** The measurement layer that sits on top of the strategy and plan docs: *what to watch, where it lives, and what number triggers what action*, across the two phases of the product's life.
> **Scope:** product + revenue + cost KPIs, split **Before monetization (1.0, live now)** vs **After monetization (1.1 IAP)**.
> **Builds on:** [`docs/plans/analytics.md`](../plans/analytics.md) (taxonomy), [`docs/plans/parameter-telemetry.md`](../plans/parameter-telemetry.md) (catalog-gap), [`docs/strategy/iap-strategy.md`](iap-strategy.md) (what to sell), [`docs/plans/iap-implementation-plan.md`](../plans/iap-implementation-plan.md) (how IAP is built).
> **Companion dashboards** (both import-only via the TelemetryDeck UI): [`Dashboard-LinkClean-Core-Usage.json`](../../apps/ios/LinkClean/docs/dashboards/Dashboard-LinkClean-Core-Usage.json) covers every Phase-1 usage KPI below; [`Dashboard-LinkClean-Monetization.json`](../../apps/ios/LinkClean/docs/dashboards/Dashboard-LinkClean-Monetization.json) is the Phase-2 IAP click-through funnel + paid-tier template (dark until 1.1). Revenue / conversion-*rate* / refund truth stays in **App Store Connect** (Sales & Trends + App Analytics), not these dashboards — see §"The measurement model".

---

## TL;DR

**The north-star is a _clean exported_** — a URL cleaned **and then copied / shared / markdown'd**, on any surface. Cleaning without export is curiosity; export is value delivered (`analytics.md` §6).

**LinkClean's economics are unusual and that shapes everything below:**

- **Zero marginal cost.** Cleaning is 100% on-device; there is no backend. RevenueCat, TelemetryDeck, and the $99/yr Apple Developer fee are *fixed/sunk*. Every Pro sale is ~pure margin. There is no per-clean, per-user, or per-action cost to model — unlike a server/LLM app, the entire "cost" half of unit economics is a flat line.
- **One-time purchase, not a subscription.** Pro is a non-consumable (`linkclean_pro_lifetime`, **$4.99** base + 3-tier regional pricing, Family Sharing OFF). So **churn, MRR/ARR, renewal rate, trial-conversion, and LTV = margin ÷ churn do not exist here** — do not import them from a SaaS playbook (see §"What does NOT apply"). "After-monetization" economics reduce to **conversion × price × downloads**, minus Apple's cut.

**What's real today vs at 1.1:** Phase 1 (everything in the Core Usage dashboard) is live on shipped 1.0 events. Phase 2 (`Paywall.*` / `Purchase.*` / `Restore.*`, the live `tier` param, RevenueCat revenue) lights up when 1.1 ships — the event names are reserved but unfired today (`iap-implementation-plan.md` Phase 0).

### Headline KPIs at a glance

| Phase | North-star / headline | Target | Source |
|---|---|---|---|
| 1 | **Exports per active user / week** (clean → copy/share) | trend up; ≥ ~3/wk for a "working" loop | TelemetryDeck |
| 1 | **Activation: install → first export** | ≥ ~50% reach a first export | TelemetryDeck |
| 1 | **Surface mix** (app vs extension exports) | — *(diagnostic, not a target — decides where to invest)* | TelemetryDeck |
| 1 | **D7 retention** | trend up | TelemetryDeck (built-in) |
| 1 | **Custom-param view → add** (top premium candidate) | — *(calibration for 1.1 gating)* | TelemetryDeck |
| 2 | **Install → Pro conversion** | **≥ 5%** (floor 4%) | **RevenueCat** |
| 2 | **Net revenue / 10K downloads** | ~$2,120 @ 5% / $4.24 net | RevenueCat |
| 2 | **Review rating** | ≥ 4.7★; watch "why pay for X" | App Store Connect |

---

## The measurement model (read this first)

> **⚠️ Engine update 2026-06-10.** 1.1 shipped on **StoreKit 2, not RevenueCat**. Everywhere below that names **RevenueCat** as the source of truth for revenue, conversion *rate*, refunds, or cohort splitting, read **App Store Connect** (Sales & Trends for money; App Analytics for cohorts/conversion). There is no RevenueCat account, dashboard, or cost line (the "RevenueCat free < $2.5K MTR" ceiling notes are moot). The TelemetryDeck purchase funnel is unchanged (`Pro.Purchase.*`, client-side, blind to refunds — directional). Grandfathering (#19) was dropped, so there is no 1.0-cohort split to manage in 1.1.


Five framing facts; the KPIs only make sense against them.

### 1. Two tools, joined at *dimension* grain — never user grain

Per `iap-implementation-plan.md` ("Measurement architecture") the analytics ID and the billing ID are deliberately kept separate, so the two tools **never join at user grain**. Each owns a half and neither rebuilds the other's:

| Question | Owner |
|---|---|
| Activation, retention, core loop, surface mix, feature adoption | **TelemetryDeck** |
| Behavior → paywall → purchase **funnel** (behavioral context) | **TelemetryDeck** (analytics-ID grain) |
| Do Pro users behave differently? Which surface converts? | **TelemetryDeck**, sliced by the `tier` param |
| **Revenue, conversion _rates_, refunds** | **RevenueCat** — authoritative; never rebuilt in TelemetryDeck |
| Per-customer lookup, paywall A/B | RevenueCat |
| Downloads, installs by territory, ratings | App Store Connect |

The join dimension is **`tier`** (low-cardinality: `free` / `pro`), wired as a default parameter on every signal. The TelemetryDeck purchase funnel and RevenueCat's revenue charts are **expected not to reconcile exactly** (client-side funnel is blind to refunds and off-device events) — that's by design, not a bug.

### 2. Cost ≈ 0 → unit economics is conversion, not cost

No server, no per-use cost. The only recurring cost is the **$99/yr Apple Developer Program** fee (RevenueCat is free under $2.5K monthly tracked revenue; TelemetryDeck free under 100K signals/mo — see §Appendix ceilings). **Break-even is ~24 Pro sales/year** ($99 ÷ $4.24 net). Everything past that is profit. There is no cost curve to manage — so the entire economic question is *"how many installs convert, at what price."*

### 3. One-time purchase → the SaaS metrics don't apply (§"What does NOT apply")

### 4. Surfaces separate by event name (no extra instrumentation)

LinkClean cleans from three surfaces; they separate cleanly because the **event names differ**:

| Surface | Export event(s) | Tool signal |
|---|---|---|
| **Home** (in-app) | `Home.URL.copied`, `Home.URL.shared` | app target |
| **Clean** share extension | `Action.Clean.succeeded` | `LinkCleanAction` |
| **Markdown** share extension | `Action.Markdown.succeeded` | `LinkCleanMarkdownAction` |
| **History** (re-export of a past clean) | `History.Entry.actioned` | app target |

TelemetryDeck's built-in `extensionIdentifier` default parameter *also* tags every extension signal automatically (`analytics.md` §7), so the two extensions are separable from each other if needed — but the **headline surface mix is computed from event names**, which is bulletproof. The planned per-target `surface` param (`app`/`action`/`markdownAction`) is a 1.1 nicety, **not required** for Phase 1.

### 5. DAU / installs come from TelemetryDeck's built-in signals

There is **no custom `App.launched`** event. The SDK auto-emits:

- **`TelemetryDeck.Session.started`** → unique users per day = **DAU** (per `analytics.md` §4).
- **`TelemetryDeck.Acquisition.newInstallDetected`** → **new installs**.

> ⚠️ **Verify the exact signal-type strings in your TelemetryDeck instance.** These were renamed in the SDK 2.0 "Grand Rename" (`newSessionBegan` → `TelemetryDeck.Session.started`). If the DAU / installs charts read empty after import, the SDK version is emitting the old names — adjust the `type` selector. ([TelemetryDeck Grand Rename](https://telemetrydeck.com/blog/grand-rename/))

---

## Quick reference — every KPI

| Live @1.0? | # | KPI | Phase | Primary source | Target / threshold |
|---|---|---|---|---|---|
| ✅ **headline** | 0 | **Exports per active user / week** (north-star) | 1 | TelemetryDeck | ≥ ~3/wk; trend up |
| ✅ | 1 | New installs / day | 1 | TelemetryDeck (`newInstallDetected`) | trend up |
| ✅ | 2 | DAU / WAU (+ stickiness) | 1 | TelemetryDeck (`Session.started`) | DAU/WAU > 20% |
| ✅ | 3 | Activation — install → first export | 1 | TelemetryDeck | ≥ 50% |
| ✅ | 4 | Onboarding completion + extension-guide reach | 1 | TelemetryDeck | completion ≥ 80% |
| ✅ | 5 | Home cleans / day + clean → export conversion | 1 | TelemetryDeck | conversion ≥ 60% |
| ✅ | 6 | **Surface mix** — app vs extension | 1 | TelemetryDeck | diagnostic |
| ✅ | 7 | Input-source mix + auto-paste annoyance | 1 | TelemetryDeck | invalid-paste < 10% |
| ✅ | 8 | Retention D1 / D7 / D30 | 1 | TelemetryDeck (built-in) | D7 trend up |
| ✅ | 9 | **Custom-param view → add + depth** (premium #1) | 1 | TelemetryDeck | calibration |
| ✅ | 10 | History size distribution + export-path mix | 1 | TelemetryDeck | calibration (14-day gate) |
| ✅ | 11 | Markdown adoption + title reliability (premium #2) | 1 | TelemetryDeck | reliability ≥ 95% |
| ✅ | 12 | Catalog-gap health (reference / leftover / kinds) | 1 | TelemetryDeck | gap shrinking |
| ✅ | 13 | Extension reliability (failures by reason) | 1 | TelemetryDeck | failure < 5% |
| ✅ | 14 | **Cost** (fixed only) | 1 | manual | break-even ~24 sales/yr |
| ⏳ 1.1 | 15 | **Install → Pro conversion** | 2 | **RevenueCat** | ≥ 5% (floor 4%) |
| ⏳ 1.1 | 16 | Paywall funnel by trigger / surface | 2 | TelemetryDeck | which gate converts |
| ⏳ 1.1 | 17 | **Net revenue / 10K downloads** + price realization | 2 | RevenueCat | ~$2,120 @ 5% |
| ⏳ 1.1 | 18 | Refund rate | 2 | RevenueCat | < 5% |
| ⏳ 1.1 | 19 | Grandfathering & cohort hygiene | 2 | RevenueCat | exclude 1.0 cohort from conversion |
| ⏳ 1.1 | 20 | `tier`-sliced behavior (do Pro users differ) | 2 | TelemetryDeck | — |

Legend: ✅ live on shipped 1.0 events · ⏳ 1.1 reserved-but-unfired until IAP ships.

---

# Phase 1 — Before monetization (1.0, live now)

The pre-revenue job is two-fold: **(a)** prove the core loop works and is habit-forming, and **(b)** calibrate 1.1's gating on today's all-free behavior, so the paywall launches data-backed instead of guessed. Every KPI here runs on events shipping in 1.0; all are in the Core Usage dashboard.

## 0. North-star — exports per active user / week

**The headline.** A *clean exported* is the value moment. Cleaning alone is curiosity.

- **Definition:** `count(export events) ÷ unique_users(export events)`, weekly. Export set = `Home.URL.copied` + `Home.URL.shared` + `Action.Clean.succeeded` + `Action.Markdown.succeeded`. (History re-actions are tracked separately in #10 to avoid double-counting a re-export of an old clean.)
- **Source:** TelemetryDeck.
- **Target:** ≥ ~3/week for a "working" loop; the trend matters more than the level. A decline means the loop or the catalog quality is regressing even if installs hold.
- **Action:** below ~3/wk → product investigation (which surface dropped? cross-ref #6 surface mix and #12 catalog gap).

> **Doc-sync note:** `Home.URL.shared` ships in code (`AnalyticsEvent.swift`) but is missing from the `analytics.md` §6 table — fold it in when that doc is next touched. The north-star export set depends on it.

## 1. New installs / day

- **Definition:** `count(TelemetryDeck.Acquisition.newInstallDetected)` per day.
- **Why:** the top of every funnel and the denominator for activation (#3) and (post-1.1) conversion (#15). Watch for App Store ranking / review-driven step changes.
- **Action:** pair with App Store Connect impressions → product-page conversion for the acquisition side (ASC owns that half).

## 2. DAU / WAU + stickiness

- **Definition:** unique users on `TelemetryDeck.Session.started`, daily and weekly. **Stickiness = DAU ÷ WAU** (or DAU/MAU).
- **Why:** the foundation under everything. But note: LinkClean is **episodic by nature** — people clean links in bursts, not daily. A modest DAU/WAU is *not* automatically bad here the way it would be for a daily-habit app; read it alongside retention (#8) and exports/user (#0), not in isolation.
- **Target:** DAU/WAU > 20% is healthy; treat as directional given the episodic usage.

## 3. Activation — install → first export

- **Definition:** share of installs that reach a **first export** (any export event). The Core Usage dashboard ships a lifetime proxy = `unique_users(export events) ÷ unique_users(newInstallDetected)`; the true *time-boxed* "first export within 24h of install" needs TelemetryDeck's built-in **Funnel** insight (`newInstallDetected` → export), built in the UI.
- **Why:** "installed" is worthless; "got value once" predicts retention. The riskiest sub-step is **first _extension_ export** — the share extension must be manually enabled in the share sheet (`analytics.md` §1).
- **Target:** ≥ 50% reach a first export. Below → the install-to-first-value bridge is broken (onboarding, empty state, or the extension-enablement guide #4).

## 4. Onboarding completion + extension-guide reach

- **Definition:** completion = `Onboarding.Flow.completed ÷ (completed + skipped)`; reach = `Onboarding.ExtensionGuide.shown` by `source` (`onboarding` / `settings`).
- **Why:** enabling the action extension is *the* single highest-leverage activation step (it's how LinkClean becomes a one-tap habit instead of a copy-paste app). The guide's reach is the leading indicator of extension adoption (#6).
- **Target:** completion ≥ 80%; if extension-guide reach is low while extension exports (#6) are low, the guide — not the extension — is the bottleneck.

## 5. Home cleans / day + clean → export conversion

- **Definition:** volume = `count(Home.URL.cleaned)`; conversion = `(Home.URL.copied + Home.URL.shared) ÷ Home.URL.cleaned`.
- **Why:** separates *curiosity* (cleaned, walked away) from *value* (exported). A high clean count with low export conversion means the result isn't trusted or the copy/share affordance is weak.
- **Target:** in-app clean → export ≥ 60%. Also watch the **`changed` rate** (`Home.URL.cleaned[changed=true]` share): a low changed-rate means either catalog gaps (#12) or users re-cleaning already-clean URLs.

## 6. Surface mix — app vs extension *(the load-bearing diagnostic)*

- **Definition:** app exports (`Home.URL.copied`+`Home.URL.shared`) vs extension exports (`Action.Clean.succeeded`+`Action.Markdown.succeeded`), per day.
- **Why:** **decides where IAP gating can live.** If extensions dominate, the main app is a configuration shell and the paywall must be reachable from an extension-driven moment — but the strategy doc forbids paywalls *inside* extensions (`iap-strategy.md` §9 rule 1), so a heavy-extension mix means the paywall must catch users on their *next app open*, not mid-share. This single chart shapes the entire 1.1 paywall placement.
- **Action:** not a target — an input to the 1.1 paywall-placement decision.

## 7. Input-source mix + auto-paste annoyance

- **Definition:** `Home.URL.cleaned` by `source` (`autoPaste` / `manualPaste` / `typed`); annoyance = `count(Home.Clipboard.invalidPasted)`.
- **Why:** validates the auto-paste default. A high invalid-paste rate (auto-paste firing on non-URL clipboards) is friction that may justify turning the default off; cross-ref `Settings.AutoPaste.toggled[enabled=false]`.
- **Target:** invalid-paste < ~10% of Home opens.

## 8. Retention — D1 / D7 / D30

- **Definition:** TelemetryDeck's **built-in Retention insight** on `TelemetryDeck.Session.started`. *(Not a custom TQL insight — build it in the UI; it isn't in the JSON.)*
- **Why:** the truest PMF signal and the **pre-1.1 input to the subscription-vs-one-time question** — which is already decided (one-time), and the retention curve shape *validates* that call: a quick taper confirms a lifetime unlock over a subscription (`analytics.md` §10).
- **Target:** D7 trending up release-over-release.

## 9. Custom-parameter funnel + depth *(premium candidate #1)*

- **Definition:** view → add = `unique_users(Parameters.Custom.added) ÷ unique_users(Parameters.Custom.shown)`; depth = `Parameters.Custom.added` by `totalCount` bucket (`0`/`1`/`2`/`3-4`/`5-9`/`10+`).
- **Why:** custom-parameter *creation* is the #1 thing 1.1 gates (`iap-strategy.md` §6). The view→add split separates a **discovery** problem (few reach the screen) from a **value** problem (reachers don't add). The depth tail shows whether there's a power-user segment worth gating — gating a feature nobody goes deep on converts nobody.
- **Action:** healthy view→add + a real depth tail → the gate will convert. Low add despite healthy views → the *feature value* needs work before it's worth gating.

## 10. History size distribution + export-path mix

- **Definition:** size = `History.Screen.shown` by `entryCount` bucket (`0`/`1-9`/`10-49`/`50+`); paths = `History.Entry.actioned` by `action` (`copy`/`share`/`markdown`/`openInBrowser`).
- **Why:** sizes the **14-day history-window gate** — if most users sit at `1-9` entries, the window bites almost nobody and won't drive conversion; a fat `50+` tail means the buried-archive upgrade pitch has teeth (`iap-strategy.md` §6). The path mix shows Markdown demand *outside* the extension and whether history is a real re-export surface or a dumping ground.
- **Action:** input to whether the 14-day window is the right gate or needs a different trigger.

## 11. Markdown adoption + title reliability *(premium candidate #2 / growth engine)*

- **Definition:** adoption = `count(Action.Markdown.succeeded)` per day; reliability = same, by `titleSource` (`javascript`/`linkPresentation`/`urlOnly`).
- **Why:** Markdown is the **viral PKM feature and the growth engine** — it ships free and stays free (`iap-strategy.md` §12). `urlOnly` means title extraction failed (no nice `[title](url)`), degrading the feature; a rising `urlOnly` share is a reliability regression to fix. HTML / Title+URL formats are the *future* Pro formats this validates demand for.
- **Target:** non-`urlOnly` (i.e. a real title) ≥ 95% of Markdown actions.

## 12. Catalog-gap health

- **Definition:** reference matches = `Parameters.Reference.observed` by `parameter` (top known-but-not-default trackers slipping through); leftover sizing = `Home.URL.cleaned` / `Action.Clean.succeeded` by `leftoverCount` bucket; category value = by `removedKinds`.
- **Why:** LinkClean's quality is bounded by whether the catalog matches real trackers (`parameter-telemetry.md` §1). The `Parameters.Reference.observed` stream is the **workhorse** — every top entry is a public, safe tracker name to promote into the default catalog from real usage. `removedKinds` shows which of the 7 categories earn their keep.
- **Action:** promote the top `Parameters.Reference.observed` names into defaults; a category that never fires in `removedKinds` is dead weight. Privacy bright line: only *public reference-catalog* names and *counts* are collected — never arbitrary URL keys (`parameter-telemetry.md` §2).

## 13. Extension reliability — failures by reason

- **Definition:** `Action.Clean.failed` by `reason` (`noURL` / `invalidInput`).
- **Why:** host-app compatibility gaps. A `noURL` spike on a specific share path (the known Google Maps share issue) is a concrete bug to chase. Cross-check delivered `Action.*` signals against shared-store `HistoryEntry` row counts to measure extension delivery loss before trusting absolute extension volumes (`analytics.md` §8).
- **Target:** failure < 5% of extension invocations.

## 14. Cost — fixed only

- **The whole section, honestly:** there is **no variable cost**. Recurring spend = **$99/yr** Apple Developer Program. RevenueCat (free < $2.5K MTR) and TelemetryDeck (free < 100K signals/mo) are $0 at current and near-term scale.
- **Break-even:** ~24 Pro sales/year at $4.24 net. There is nothing to optimize on the cost side; the leverage is 100% on conversion and acquisition. *This is the single biggest difference from a server/LLM product and the reason most of a typical "unit economics" workbook is N/A here.*

---

# Phase 2 — After monetization (1.1 IAP)

Reserved-but-unfired today. The event names exist in the analytics facade shipped unfired (`iap-implementation-plan.md` Phase 0); they light up when 1.1 flips them on. **Revenue truth lives in RevenueCat, not TelemetryDeck** — the TelemetryDeck half is purely behavioral context.

## 15. Install → Pro conversion *(the headline revenue KPI)*

- **Definition:** Pro purchases ÷ eligible installs. **RevenueCat is the source of truth** for the rate (cohort-aware, refund-reconciled). TelemetryDeck gives a real-time *leading* read via the funnel (#16) but drifts above RC by the refund rate.
- **⚠️ Cohort hygiene:** the denominator must be **post-1.1 installs only**. The entire 1.0 cohort is granted Pro *for free* via grandfathering (`originalApplicationVersion`, `iap-strategy.md` §7) — they are `pro` without a sale and would both inflate "Pro share" and corrupt "conversion" if mixed in. See #19.
- **Target / decision rules** (`iap-strategy.md` §5, evaluate ~60 days post-1.1):

  | Conversion | Reading | Action |
  |---|---|---|
  | < 4% | below floor | drop to $3.99 permanently; survey non-converters; reassess which features gate |
  | 4–7% | validated | hold $4.99 |
  | > 7% | upside | hold; consider $5.99 only for a *future, fatter* Pro bundle — never the same features |

## 16. Paywall funnel by trigger / surface

- **Definition:** `Paywall.shown[trigger]` → `Purchase.started[trigger]` → completed, per placement. Triggers (`iap-strategy.md` §9): history-window loss banner, locked-feature tap (add custom param), Settings Pro row. **TelemetryDeck**, analytics-ID grain, for *behavioral context* ("cleaned 3 links via extension → saw paywall → bought").
- **Why:** tells you **which gate actually converts**, so you lead with it. RevenueCat owns the conversion *rate*; this owns the *which-moment* attribution RC can't see at behavior grain.
- **Reserved event names** (finalize on the `Feature.Subject.verbPast` convention before wiring — the two plan docs currently disagree, `analytics.md` §9 vs `iap-implementation-plan.md` Phase 0): `Paywall.Screen.shown(trigger)`, `Paywall.Screen.dismissed(trigger)`, `Paywall.Purchase.started(trigger, product)`. Completion/refund arrive via RevenueCat.

## 17. Net revenue / 10K downloads + price realization

- **Definition:** the per-10K-download model (downloads are the unpredictable input, so normalize them out — `iap-strategy.md` §11):

  | Conversion | Pro sales | Net @ $4.24 |
  |---|---|---|
  | 3% (downside) | 300 | **$1,272** |
  | 5% (base) | 500 | **$2,120** |
  | 7% (upside) | 700 | **$2,968** |

- **Price realization** (App Store Connect, by product/territory): no launch promo; **$4.99 base nets $4.24**, regional tiers net ~$1.69 (Tier 3) – $2.54 (Tier 2); **blended net depends on where installs land** (weight by storefront mix). Track the blended net, not the sticker price.
- **Revenue is read from App Store Connect only** (Sales & Trends). Client-side revenue analytics (`TelemetryDeck.purchaseCompleted(transaction:)`) was **dropped 2026-06-10** — no transaction or amount is sent to TelemetryDeck. The `Pro.Purchase.*` events are count-only (paywall conversion), not revenue.

## 18. Refund rate

- **Definition:** refunds ÷ purchases (RevenueCat tracks refunds as negative revenue). **RevenueCat only** — the client-side TelemetryDeck purchase signal can't see refunds.
- **Target:** < 5%. A spike concentrated on one paywall trigger means that gate over-promised — cross-ref #16.

## 19. Grandfathering & cohort hygiene

- **Definition:** the 1.0 cohort entitled to Pro via `originalApplicationVersion < first-1.1-build` (`iap-strategy.md` §7). These are `pro`-without-a-sale.
- **Why it's a KPI, not a footnote:** every Phase-2 rate (#15, #17) is wrong if this cohort is mixed in. Segment **all** revenue/conversion reads to the **post-1.1 install cohort**. RevenueCat's `originalApplicationVersion` is the splitter. Also: **Family Sharing is OFF** (2026-06-10) — one purchase entitles one Apple Account, so revenue-per-purchase = revenue-per-entitled-user; no family-share dilution to model.

## 20. `tier`-sliced behavior — do Pro users differ?

- **Definition:** re-run the Phase-1 engagement KPIs (#0, #5, #9, #10) sliced by the `tier` default parameter (`free` / `pro`).
- **Why:** the post-IAP product question — are Pro users more engaged, and on which gated feature? The `tier` param ships in 1.0 as the literal `"free"` (so the launch cohort stays schema-compatible) and switches to the live `EntitlementStore` read at 1.1 (`iap-implementation-plan.md` Phase 0 / §"Measurement architecture"). **It cannot be backfilled** — the pre-IAP cohort is stamped exactly once.

---

## What does NOT apply (and why) — don't import these from a SaaS playbook

LinkClean is a **zero-marginal-cost, one-time-purchase, on-device utility.** A pile of standard unit-economics KPIs are *undefined* here, not merely unmeasured. Spelling them out so they don't get cargo-culted from a subscription/LLM template (e.g. the Whyzard unit-economics workbook this doc is modeled on, which is mostly about exactly these):

| Metric | Why it doesn't apply |
|---|---|
| **Churn / retention-of-payment** | A non-consumable can't churn — you own it forever. (User *engagement* retention #8 still matters; *revenue* retention is a constant.) |
| **MRR / ARR** | No recurring revenue. Revenue is a one-time event per buyer; model cumulative, not monthly-recurring. |
| **LTV = margin ÷ churn** | Undefined (churn = 0). LTV ≈ the single net sale (~$4.24), plus the option value of future Pro features the buyer already owns via "all future Pro features." |
| **Trial-start / trial-conversion funnel** | Non-consumables have no free-trial mechanics. **The free tier _is_ the trial** (`iap-strategy.md` §4). |
| **Cost per action / COGS / gross margin %** | No variable cost. Margin is ~100% of net after Apple's cut; there's no COGS line. |
| **Token/compute burn, cache-hit rate, cost-per-user/mo** | No backend, no LLM. Cleaning is on-device. (The closest analog — Whyzard's headline — is simply $0 here.) |
| **Cap-hit / usage-cap conversion pressure** | The core action is **never capped** (`iap-strategy.md` §12). Conversion pressure comes from the rolling 14-day history window and locked *additions*, not a usage meter. |

---

## Appendix

### Free-tier ceilings (when does this start costing money)

| System | Plan | Limit | LinkClean headroom |
|---|---|---|---|
| TelemetryDeck | Free | 100K signals/mo, no query API | ~3K MAU at a typical signal rate; CSV export only on free |
| RevenueCat | Free | < $2.5K monthly tracked revenue | well clear at modeled volumes |
| App Store Connect | — | — | downloads / ratings / territories, free |
| Apple Developer | $99/yr | — | the *only* recurring cost (see #14) |

### Dashboard convention (mirrors `iap-strategy.md`'s tooling discipline)

TelemetryDeck custom dashboards are **import-only via the UI — no API to re-apply.** The JSON is the durable source of truth. Workflow: build/edit in the UI → **Actions → Export Dashboard** → commit over the matching file in `docs/dashboards/` (`Dashboard-LinkClean-Core-Usage.json` / `Dashboard-LinkClean-Monetization.json`). The reverse (edit JSON → **Import Dashboard**) also works — the file was hand-authored in the verified export format `{title, insights[], _exportMetadata}` with TQL carried per-insight as `customQuery`. **TQL sharp edge:** every `postAggregation` needs a `name`, including a `thetaSketchEstimate` nested inside an arithmetic's `fields`, or the import fails; `_`-prefixed names stay hidden from chart output.

### The two dashboards — and what stays in RevenueCat

The KPIs split across two importable TelemetryDeck dashboards **by function, not phase**: **Core Usage** (acquisition, the clean→export loop, surface mix, feature adoption, catalog-gap health — the Phase-1 KPIs, live now) and **Monetization** (the paywall click-through funnel #16 + paid-tier penetration #20 — a dark template that reads empty until 1.1 fires the events; a flat zero before then is expected, not a regression). What stays **out** of both, in RevenueCat: revenue, conversion *rates*, and refunds (#15, #17, #18) — not rebuildable in TelemetryDeck and not to be duplicated. The Monetization dashboard's `Paywall.*` event names are provisional (the plan docs disagree); finalize them against the `AnalyticsEvent` facade when the IAP cases land, then re-point the `type` selectors.

### Reserved-but-unfired 1.1 events (so Phase 2 lights up with a baseline, not a blank)

`Paywall.Screen.shown / dismissed`, `Paywall.Purchase.started`, plus the `tier` default param flip (client-side **revenue** via `purchaseCompleted` was later **dropped 2026-06-10** — ASC owns money). Reserved in the facade today (`iap-implementation-plan.md` Phase 0); **neither `tier` nor `surface` default params nor any `Purchase.*` event is wired in the shipped 1.0 build** — Phase 1 deliberately depends on none of them.

### Re-evaluate this doc when

1.1 ships (IAP live) · the 14-day history window or any gate value changes · a new Pro feature ships · the default model of the app changes · TelemetryDeck renames built-in signals again · `Parameters.Reference.observed` data is rich enough to drive a default-catalog expansion (`parameter-telemetry.md` §11).
