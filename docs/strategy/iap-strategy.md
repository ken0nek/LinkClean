# LinkClean IAP Strategy

> **Status: proposed** — 2026-06-05. Sequencing (free 1.0 → IAP-only 1.1, timeboxed) **decided** 2026-06-05 — see §8.
> Scope: **what** to sell — product lineup, pricing, free-tier limits, gated features, grandfathering, paywall triggers. This is the "IAP strategy" item in `docs/TODO.md` (1.1.0) and answers everything `docs/plans/iap-implementation-plan.md` defers ("Out of scope / deferred").
> Sources: consolidated from `docs/raw/LinkKit_Monetization_Strategy.md` (v1) and `docs/raw/LinkKit_Monetization_Strategy_v3.md` (v3), both Feb 2026 exports written under the old working name "LinkKit" against a pre-1.0 feature plan. Where they conflict, v3 (the later iteration) generally wins; where both conflict with the shipped app, reality wins. Deviations are logged in §10.

---

## 1. Context (June 2026)

- **1.0 has not shipped.** It ships fully free, no IAP (`docs/TODO.md`). IAP lands in **1.1** via RevenueCat.
- **Already built and free in 1.0:** URL cleaning (Home + `LinkCleanAction`), Markdown copy (`LinkCleanMarkdownAction` + `MarkdownFormatter` + title fetch), history **with search** (`HistoryView` is `.searchable`), custom parameters, default-parameter toggles.
- **Not built yet:** HTML / Title+URL formats, history export, domain rules, iCloud sync, widgets, Shortcuts.
- The raw docs' launch choreography (soft-launch weeks, 60-day download targets) is superseded: **1.0-free → 1.1-IAP *is* the soft launch**, with real review-building and zero monetization friction at first contact.

### The central tension (unchanged from v1)

The market leader (Clean Links by Numen) is completely free with a 5.0 rating. LinkClean cannot win as a cheaper tracker-stripper. It wins as a **link productivity tool** — formats, searchable history, custom rules — for people who *work with links*: note-takers, researchers, developers, bloggers. That user pays for workflow; the casual privacy user never will. Every gating decision below follows from this split: **the privacy utility is free, the productivity layer is Pro.**

---

## 2. Competitive landscape (Feb 2026 snapshot — re-verify before 1.1 ships)

| App | Model | Price | Lesson |
|-----|-------|-------|--------|
| Clean Links (Numen) | 100% free | $0 | Sets the "why pay?" baseline; free tier must be genuinely good |
| CleanSend | Subscription | $2.99/mo (~$36/yr) | Subscriptions for static utilities are resented |
| Remove Tracking | Sub + lifetime hedge | $6.99/yr or $9.99 life | Lifetime option alongside a sub = sub churn is real |
| Clean Share | Paid upfront | $2.99 | 2 ratings — upfront price kills discovery |
| PrivateLink | Tiered unlock | $0.99 Pro | Small one-time unlocks are accepted |
| Trackless Links | Paid upfront | $5.99 | Category price ceiling; 4.6★ from power users |
| AI Link Cleaner | Freemium | 10/day free; $100 life | Usage caps on the core action + absurd pricing → public backlash |
| SneakShare | Free + tip jar | $0.99–4.99 tips | Goodwill, not a business (1–3% conversion) |
| Pure Link | Gated trial | 3 free cleans | Hostile gating destroys trust |

**Patterns:** subscriptions resented for utilities; paid-upfront kills growth; tip jars aren't revenue; one-time unlocks work when value is understood before paying; ceiling ≈ $5.99.

---

## 3. The model: freemium + one-time Pro unlock

| Model | Adoption | Revenue | Sentiment | Verdict |
|-------|----------|---------|-----------|---------|
| 100% free | ★★★★★ | ☆ | ★★★★★ | 1.0 phase only |
| Paid upfront | ★ | ★★★ | ★★ | No — kills discovery |
| Subscription | ★★ | ★★★★ | ★ | No — utility mismatch, privacy users especially suspicious |
| Tip jar only | ★★★★★ | ★ | ★★★★ | Supplement at most (deferred, §8) |
| Ads | ★★★★ | ★★ | ☆ | Never — privacy contradiction |
| **Freemium + one-time** | ★★★★ | ★★★ | ★★★★ | ✅ **Chosen** |

"Pay once, own forever" is itself a marketing message against CleanSend's $36/year, and the free tier competes head-on with Clean Links.

---

## 4. Product lineup (answers implementation-plan "product mix")

- **One non-consumable**: "LinkClean Pro". Suggested product ID `linkclean_pro_lifetime`, mapped to RevenueCat entitlement **`pro`** (matches the implementation plan's placeholder).
- **No subscription** — not now, not alongside. Dual models confuse users and erode trust (v1 §6).
- **No free trial / intro offer mechanics** — non-consumables don't support them; **the free tier is the trial**. Urgency comes from launch pricing (§5) and the rolling history window (§6).
- **Family Sharing: ON** for the non-consumable from day one. Goodwill aligned with the "respect users" positioning; revenue risk negligible at this price. Treat as irreversible once enabled.

---

## 5. Pricing

### Regular price: $4.99 · Launch price: $3.99 (first 30 days of 1.1)

v1 argued $2.99, v3 argued $4.99; v3's value-based case wins (see §10 for the dissent):

- A 5-links/day Obsidian user saves ~5 hours/year of manual formatting and keeps ~1,800 searchable links/year. $4.99 pays for itself in weeks.
- Under $5 is still impulse territory; $5.99+ crosses into "let me think about it."
- Positioning: undercuts Trackless Links ($5.99), is one-seventh of CleanSend's first year, and the conversion drop from $3.99→$4.99 is typically <10% — net revenue favors $4.99.

The **$3.99 launch price** rewards the first wave, creates a real (non-dark-pattern) deadline, and gives a cheap A/B read on price sensitivity.

### Decision rules (evaluate ~60 days after 1.1)

- Conversion **< 4%** → drop to $3.99 permanently, survey non-converters, reassess which features gate.
- Conversion **4–7%** → price validated, hold.
- Conversion **> 7%** → hold $4.99; consider $5.99 only for a future, fatter Pro bundle — never for the same features.

### Regional pricing

Use App Store Connect price points; don't sell at US-equivalent prices in price-sensitive markets (v3's example: India at an effective $1.99 can out-earn $4.99 by ~3× on volume). Indicative tiers — set actual price points at 1.1 ASC setup:

| Market group | Target |
|---|---|
| US / UK / CA / AU / EU / JP | $4.99-equivalent tier (JP ≈ ¥700–800) |
| MX / SE Asia | ≈ $2.99 equivalent |
| IN / BR / TR | ≈ $1.99 equivalent |

Net revenue assumption throughout: Apple Small Business Program (15%) → **$4.24 net** at $4.99, **$3.39** at $3.99. Requires SBP enrollment.

---

## 6. Free tier and gating matrix

Three rules generate the matrix:

1. **Never gate the core action.** Cleaning is unlimited, everywhere, forever. No usage caps (AI Link Cleaner's mistake), no extension paywalls — the extensions *are* the product.
2. **Never take back what 1.0 shipped free.** Markdown has its own action extension; history search is live; default toggles are live. Clawing any of it back in 1.1 is a bait-and-switch and would harvest 1-star reviews. (This is where v3's matrix gets overridden — §10.)
3. **Gate accumulation and addition, not operation.** History *depth* gates; custom-rule *creation* gates; new formats arrive gated. Everything a free user already relies on keeps working.

| Feature | Status today | Free | Pro |
|---------|--------------|------|-----|
| URL cleaning (app + both extensions) | shipped | ✅ unlimited | — |
| Default parameter removal | shipped | ✅ | — |
| Default parameter toggles | shipped | ✅ (correctness escape hatch — a user must be able to un-break a site) | — |
| Copy as Clean URL | shipped | ✅ | — |
| Copy as Markdown (incl. extension, title fetch) | shipped | ✅ (the viral feature — PKM word-of-mouth is the growth engine) | — |
| History — last **14 days**, searchable | shipped (window is new in 1.1) | ✅ | — |
| History — older than 14 days | 1.1 | ❌ hidden, **never deleted** | ✅ unlimited, searchable |
| Custom parameters — existing ones keep applying | shipped | ✅ (keep-what-you-have) | — |
| Custom parameters — add new | shipped | ❌ | ✅ |
| Copy as HTML / Title+URL | not built | ❌ | ✅ when built |
| History export (CSV/JSON) | not built | ❌ | ✅ when built |
| Domain-specific rules, iCloud sync, widgets, Shortcuts | not built | ❌ | ✅ — "all future Pro features" is part of the pitch |

### Why 14 days, not an item count

v1 said 25 items, an earlier draft said 50; v3's time-based reframe is strictly better and is adopted:

- "Two weeks back" is intuitive; "50 items" requires mental math.
- Usage-agnostic: the 3-links/day user and the 20-links/day user get the same deal; heavy use isn't punished, so there's no incentive to ration the app.
- Habit formation takes ~7–14 days; the limit bites only *after* the value is internalized.
- A rolling window produces **recurring** loss (something ages out every day) — the one-time-purchase substitute for subscription urgency.

**Implementation:** entries older than 14 days are hidden for free users, **not purged** (deviation from v3's 30-day purge — §10). Storage cost is trivial (local SwiftData rows), and the buried archive is the strongest upgrade pitch we have: *"You've cleaned 312 links. Pro keeps every one of them searchable."* Deleting it deletes the reason to upgrade.

### History search stays free

v3 gated search; this doc doesn't. It already shipped free (`HistoryView.searchable`), and a visible-but-disabled search field over 14 days of data is hostile UX for near-zero conversion gain. The Pro value is *unlimited searchable depth* — search over two weeks is a teaser, search over two years is the product.

---

## 7. Grandfathering the 1.0 cohort

**Decision: the entire 1.0 cohort gets Pro, free, permanently.**

- It's the raw docs' own recommendation (v3 §6), it's what Carrot Weather / Halide / Bear did, and the cohort is small (pre-marketing, and §8's timebox keeps it that way) — the revenue forgone is rounding error against the early reviews and evangelism it buys.
- 1.0 ships custom parameters and unlimited history free; *not* grandfathering would mean 1.1 takes shipped features away from the most loyal users.

**Mechanism — nothing needs to ship in 1.0 for this.** The App Store already records it: `originalApplicationVersion` (the build number of the user's *first* download, surfaced both by StoreKit's `AppTransaction` and by RevenueCat's `CustomerInfo.originalApplicationVersion`). Inside `RevenueCatEntitlementsService`, at the same boundary that maps `CustomerInfo` → `Entitlement`:

> `originalApplicationVersion` < first 1.1 build number → `.pro`

It survives reinstall and works across devices (unlike a Keychain/App Group flag), and costs zero extra infrastructure. Cache the verdict in the existing `EntitlementStore` snapshot; resolve lazily off the critical path; unknown → `.free` (fail-closed, per the implementation plan) but re-checkable via Restore.

**Prerequisite:** build numbers must stay monotonically increasing across versions (already the `/bump` convention). Sandbox/TestFlight report `originalApplicationVersion` unreliably — test grandfathering with the DEBUG entitlement-override row, not sandbox receipts.

---

## 8. Rollout

| Phase | Version | What happens |
|-------|---------|--------------|
| **Soft launch** | 1.0 | Everything free, no IAP code paths. Goals: reviews ≥ 4.5★, bug reports before anyone has paid, App Store ranking, learn which features users love. Marketing: *"Free. No ads. No subscription. No tracking."* — claim it loudly while it's literally true, and keep it true for the free tier forever. **In parallel: start the ASC Paid Apps agreement + banking/tax now** (longest lead item; must not gate 1.1). |
| **Monetize** | 1.1 | **Timeboxed: ~4–6 weeks after 1.0, scoped to IAP only.** Pro ships at **$3.99 launch price, clearly marked** ("Launch price — regular $4.99"). 14-day window activates for non-grandfathered users; custom-param creation gates; 1.0 cohort silently gets Pro. After 30 days: $4.99. |
| **Evaluate** | 1.1 + 60d | Apply §5 decision rules using the funnel data. |
| **Expand** | 1.2+ | Each new Pro feature (HTML/Title+URL, export, sync, widgets, Shortcuts) lands behind the existing entitlement — existing Pro owners get everything, which is the "all future Pro features" promise kept. Price rises, if ever, apply to new buyers only. |
| **Tip jar** | deferred | v1 wanted it at Month 3. Deferred indefinitely: it complicates the lineup for ~1–3% conversion. Revisit only if users actively ask how to support beyond Pro. |

### Sequencing decision: IAP in 1.0 considered, rejected (2026-06-05)

Shipping with IAP at initial release was evaluated against free-first.

**It would buy:** no clawback constraints on gating (§6 rule 2 vanishes — the matrix is designable from scratch); no grandfathering machinery (§7 deleted); day-one willingness-to-pay signal; conversion data that includes the most engaged cohort instead of excluding it; immunity to 1.1 slippage.

**It would cost:** 1.0 slips behind the Paid Apps agreement, RC integration, and paywall build; the first-ever App Review stacks IAP scrutiny onto an already large surface (two extensions, clipboard access); paying users hit 1.0 bugs (refunds and 1★ instead of bug reports — the Google Maps share issue is still open); one launch beat instead of two; paywall copy written with zero usage data; the "In-App Purchases" listing badge dilutes the free-alternative-to-Clean-Links entry positioning.

**Why free-first wins here:** at realistic quiet-launch volumes (2–5K downloads × 5% × ~$4) the revenue at stake is a few hundred dollars — noise. The decision is *ship weeks sooner with cleaner review optics* vs *skip grandfathering and learn WTP sooner*, and free-first's only structural weakness is gap slippage. So it holds **only with two discipline rules**:

1. **Start the Paid Apps agreement + banking/tax immediately**, in parallel with remaining 1.0 work — zero cost to start, longest lead time, must never be the reason 1.1 waits.
2. **1.1 is IAP-only and timeboxed to ~4–6 weeks after 1.0.** No feature scope rides along. If it slips materially past the timebox, the free cohort grows while revenue sits at $0 — re-read this section and re-decide rather than drift.

---

## 9. Paywall: triggers, prompts, copy

(Answers the implementation plan's "paywall triggers and design". Surface = RevenueCat dashboard paywall, so copy/layout stay server-editable.)

**Hard rules (behavioral design, from v3):**

1. **Never in the action extensions.** Mid-share interruption poisons the core flow. All gates live in the main app. (Consequence: with this gating matrix, the extensions need *no* entitlement checks in 1.1 — `EntitlementStore`'s App Group snapshot stays dormant until some future extension-side Pro feature exists.)
2. **Prompt at the moment of loss, not before.** Not "you're at 45 of 50"; instead, after entries age out: *"Links older than 14 days are hidden. Upgrade to keep your full history."*
3. **One prompt per session, max.** Dismissal is respected until next launch.
4. **Informational, never blocking.** Inline banner in History, not a modal ambush.
5. **Concrete numbers, not feature lists.** *"You've cleaned 127 links. Pro keeps all of them searchable, forever."*
6. **"Not now" is easy to find.** No dark patterns — the brand is *respecting users*.

**Triggers:**

| Trigger | Surface |
|---|---|
| Oldest history entry crosses 14 days | Inline banner atop History → tap → paywall with the user's own counts |
| Tap a locked feature (add custom parameter; later: HTML/Title+URL, export) | Lock icon + one-line value statement → paywall |
| Always available | "LinkClean Pro" row in Settings (also hosts Restore Purchases — App Review requires it reachable without purchase) |

**The pitch (one sentence):**

> **"LinkClean cleans unlimited URLs, copies as Markdown, and keeps two weeks of searchable history — free. Pro keeps your history forever, adds more formats and custom rules — $4.99, once."**

---

## 10. Deviations from the raw docs

Traceability for every place this doc overrides v1/v3:

| Topic | v1 said | v3 said | This doc | Why |
|-------|---------|---------|----------|-----|
| Price | $2.99 ($4.99 "creates deliberation") | $4.99, launch $3.99 | **v3** | Later iteration; value-based math; built-in fallback to $3.99 if conversion <4% addresses v1's risk |
| History limit | 25 items | 14 days | **v3** | Time-based is intuitive and usage-agnostic |
| Hidden-history purge | preserve ("Your history is there. Unlock it.") | purge after 30 days | **v1** | The archive *is* the upgrade incentive; storage is trivial |
| Formats | all free (marketing engine) | Markdown free; HTML, Title+URL Pro | **v3** | Hybrid keeps the viral PKM loop and still differentiates Pro; also forced — Markdown already shipped as a free extension |
| History search | Pro | Pro | **Free** (within window) | Already shipped free in 1.0; disabled search over 14 days is hostile for no gain; Pro = unlimited *depth* |
| Default parameter toggles | (free) | Pro | **Free** | Shipped free in 1.0; it's a correctness escape hatch, not a power feature; gating it risks "app broke a site and won't let me fix it" reviews |
| Launch phasing | 4 weeks free → Pro | 2-week soft launch → Pro | **1.0 free → 1.1 Pro** | Version-based reality replaces calendar choreography; same intent (reviews before monetization) |
| Grandfathering mechanism | n/a | `firstLaunchDate` + remote flag | **`originalApplicationVersion`** | Survives reinstall, cross-device, zero 1.0 work, lives at the existing RC service boundary |
| Tip jar | add at Month 3 | absent | **Deferred indefinitely** | Lineup complexity for negligible revenue at this scale |
| Revenue projections | month-by-month $38K Y1 | $45–107K Y1 | **Per-10K model only (§11)** | Both were anchored to a Feb 2026 download plan that no longer exists; downloads are the unknowable input |
| App name | LinkKit | LinkKit | **LinkClean** | Product renamed |
| v3's "CleanLink $24.99" comparisons | — | cited | **Dropped** | Not in v1's researched table; unverifiable |

---

## 11. Revenue model

Downloads are the input we can't predict (the Feb 2026 forecasts assumed a marketing plan that's moot). Conversion and price we control, so model **per 10,000 post-1.1 downloads**:

| Conversion | Pro sales | Net @ $4.24 |
|------------|-----------|--------------|
| 3% (downside) | 300 | $1,272 |
| 5% (base — industry norm for well-executed freemium utilities) | 500 | $2,120 |
| 7% (upside) | 700 | $2,968 |

Adjustments: launch-price sales net $3.39; regional-tier sales net ~$1.7–2.5; blended net realistically **~$3.90–4.10**. At v3's (optimistic) 360K year-one downloads and 5%, that's ~$70K; at a more sober 50–100K, **$10–20K** — validates a solo product, funds the developer account and infrastructure, and prices in zero growth from Pro features still unbuilt.

**Metrics that drive §5's decision rules** (funnel events already reserved in the analytics plan — `paywallShown(trigger)`, `purchaseStarted`, `purchaseCompleted`, `purchaseFailed`, `restoreCompleted`):

- Pro conversion rate (target ≥ 5%; floor 4%)
- `paywallShown → purchaseCompleted` by trigger (which gate actually converts)
- Install → purchase latency (validates the 14-day window; if median ≪ 14d, the window could tighten — but don't: trust > optimization)
- Review rating (target ≥ 4.7; watch for "why do I have to pay for X" — early signal a gate is misplaced)

---

## 12. What NOT to do (standing constraints)

- **No subscription, ever** — and say so in marketing; it's a weapon against CleanSend.
- **No usage caps on cleaning.** The core action is unlimited, always.
- **No paywall in the share/action extensions.** The extension is the product.
- **Never gate Markdown retroactively.** It's the growth engine and it shipped free.
- **Never delete a free user's hidden history.** It's the upgrade incentive and their data.
- **Nothing above $5.99**, and no second "Pro+" tier alongside — one entitlement, growing forever.
- **No ads.** A privacy app with ads is a self-refuting product.
- **No dark patterns at the paywall** — no fake urgency, no buried dismiss, no pre-loss nagging.

---

## 13. Unblocked next steps

1. **ASC (Ken, start now — parallel with remaining 1.0 work):** Paid Apps agreement + banking/tax (longest lead) → create one non-consumable (`linkclean_pro_lifetime`) at the §5 price points → RC dashboard entitlement `pro` + default offering + paywall — per implementation plan Phase A.
2. **Code (Claude):** implementation plan Phases B–C, plus the §7 grandfather mapping and §9 triggers.
3. **Before 1.1 ships:** re-verify the §2 competitive snapshot (it's from Feb 2026) — pricing moves; the $4.99 case assumes Trackless Links still anchors $5.99.
