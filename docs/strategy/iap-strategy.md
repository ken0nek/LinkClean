# LinkClean IAP Strategy

> **Status: proposed** — 2026-06-05. Sequencing (free 1.0 → IAP-only 1.1, timeboxed) **decided** 2026-06-05 — see §8.
> **Revised 2026-06-09** — revalidated the model (one-time confirmed; structural case added, §3), expanded the paywall into concrete per-surface experiences (§9), added a free basic Shortcut (§6), softened the no-subscription precommitment (§12), and named the roadmap ceiling (§11).
> **Calibrated 2026-06-09** — set the 1.1 free tier to a **validate-WTP + ASO** brief (§1): history window **10 days**, **3** free custom rules, archive **stored-and-hidden with disclosure** (not silent), default-parameter toggles kept free. Supersedes an interim 14→7 / 5→1 tightening pass (lineage in §10).
> Scope: **what** to sell — product lineup, pricing, free-tier limits, gated features, grandfathering, paywall triggers and experiences. This is the "IAP strategy" item in `docs/TODO.md` (1.1.0) and answers everything `docs/plans/iap-implementation-plan.md` defers ("Out of scope / deferred").
> Sources: consolidated from `docs/raw/LinkKit_Monetization_Strategy.md` (v1) and `docs/raw/LinkKit_Monetization_Strategy_v3.md` (v3), both Feb 2026 exports written under the old working name "LinkKit" against a pre-1.0 feature plan. Where they conflict, v3 (the later iteration) generally wins; where both conflict with the shipped app, reality wins. Deviations are logged in §10.

---

## 1. Context (June 2026)

- **1.0 has not shipped.** It ships fully free, no IAP (`docs/TODO.md`). IAP lands in **1.1** via RevenueCat.
- **Already built and free in 1.0:** URL cleaning (Home + `LinkCleanAction`), Markdown copy (`LinkCleanMarkdownAction` + `MarkdownFormatter` + title fetch), history **with search** (`HistoryView` is `.searchable`), custom parameters, default-parameter toggles.
- **Not built yet:** HTML / Title+URL formats, history export, domain rules, iCloud sync, widgets, Shortcuts.
- The raw docs' launch choreography (soft-launch weeks, 60-day download targets) is superseded: **1.0-free → 1.1-IAP *is* the soft launch**, with real review-building and zero monetization friction at first contact.

### The central tension (unchanged from v1)

The market leader (Clean Links by Numen) is completely free with a 5.0 rating. LinkClean cannot win as a cheaper tracker-stripper. It wins as a **link productivity tool** — formats, searchable history, custom rules — for people who *work with links*: note-takers, researchers, developers, bloggers. That user pays for workflow; the casual privacy user never will. Every gating decision below follows from this split: **the privacy utility is free, the productivity layer is Pro.**

### What 1.1 is for: a willingness-to-pay test (decided 2026-06-09)

1.1 is a **validation beat, not a revenue play** — the question it answers is *"does anyone pay at all, and for what?"* Two settled inputs shape every gate below:

- **Goal = validate WTP.** Gates must yield an *interpretable* signal: a non-purchase should mean "didn't value Pro," not "got annoyed." That rules out aggressive scarcity — an over-tight free tier confounds the very thing 1.1 exists to measure.
- **Growth = ASO / App Store search.** Ranking — and the rating that drives it — is the binding constraint, not conversion rate. A gate that earns a 1★ costs more in suppressed discovery than it makes in Pro sales; protecting the rating outranks squeezing conversion.

Both point the same way: **fair gates for 1.1; revisit tightening in 1.2+**, once there's paying-user data *and* real Pro features (formats / sync / AI) that make a gate feel like added value rather than removed function. The §6 free-tier settings (10-day window, 3 free custom rules) are calibrated to this brief — an interim 14→7 / 5→1 tightening was reverted to it on 2026-06-09 (§10).

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

### Why one-time fits *this* product (the structural case)

The "utility mismatch" row above is the soft version of the argument. The hard version, and the one to lead with: **the only capability in LinkClean with genuine recurring-value economics is the tracking catalog — perpetual curation as trackers evolve — and that is exactly the capability §6 rule 1 keeps free forever.** Ad blockers (1Blocker, Wipr) legitimately sell *subscriptions* on filter-list freshness; LinkClean structurally *cannot*, because gating catalog freshness would gate the core action and break the brand. Everything that *is* gateable — history depth, formats, custom rules, sync — is **build-once / own-forever** value with no recurring delivery. One-time pricing is the precise match for own-forever value; a subscription would be charging rent on a promise we've deliberately chosen not to make. This is *why* "no subscription" is principled here rather than mere preference — and it is also the model's ceiling (the promise pre-sells the roadmap, §11). The standing constraint is in §12, softened from "ever" to "not the primary model."

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

Apple's storefront model (since late 2022: ~900 price points with automatic per-storefront FX) lets you set the US base at $4.99 and manually lower individual storefronts. Don't sell at US-equivalent prices in price-sensitive markets — v3's example: India at an effective $1.99 can out-earn $4.99 by ~3× on volume. The tiers below are **purchasing-power groupings, indicative only — set actual price points at 1.1 ASC setup:**

**Tier 1 — full price** ($4.99 / £4.99 / €4.99 / A$7.99 / JP ≈ ¥700–800). High-income storefronts where $4.99 is impulse-level.

- Americas: United States, Canada
- UK & Ireland: United Kingdom, Ireland
- Eurozone: Germany, France, Italy, Spain, Netherlands, Belgium, Austria, Finland, Luxembourg, Portugal
- Non-euro Europe: Switzerland, Norway, Sweden, Denmark, Iceland
- Asia-Pacific: Japan, Australia, New Zealand, South Korea, Singapore, Hong Kong, Taiwan
- Gulf / Israel: UAE, Saudi Arabia, Qatar, Kuwait, Israel

**Tier 2 — ≈ $2.99 equivalent.** Upper-middle-income; full price would suppress conversion.

- Latin America: Mexico, Chile, Uruguay, Costa Rica, Panama
- Central / Eastern Europe: Poland, Czechia, Hungary, Romania, Croatia, Slovakia, Slovenia, Bulgaria, Estonia, Latvia, Lithuania, Greece
- Asia: Malaysia, Thailand, China mainland
- Africa: South Africa

**Tier 3 — ≈ $1.99 equivalent.** High-volume, price-sensitive — the volume play (low price × volume out-earns full price).

- South Asia: India, Pakistan, Bangladesh, Sri Lanka
- SE Asia: Indonesia, Philippines, Vietnam
- Latin America: Brazil, Colombia, Peru, Argentina, Ecuador
- EMEA: Turkey, Egypt, Nigeria, Kenya, Morocco, Ukraine

**Storefront caveats:**

- **"EU" = ~27 separate storefronts**, not one. Apple defaults the Eurozone to a single euro point; you *can* override per-storefront to discount lower-income euro members (Greece, Portugal, the Baltics), but most don't. UK and Switzerland are non-EU, priced separately.
- **Argentina & Turkey:** severe currency volatility — Apple re-prices periodically and effective USD swings 20–40%. Pin a local point and revisit.
- **China mainland:** its own ecosystem, but App Store ARPU is solid — $2.99-equiv is conservative; could test toward Tier 1. No special compliance for a simple paid unlock.
- **Russia:** App Store purchases suspended since 2022 — can't realistically sell Pro; exclude from planning.
- Borderline / later A/B targets: China (2↔1), Colombia (3↔2), Portugal & Greece (Tier 1, discountable).

Net revenue assumption throughout: Apple Small Business Program (15%) → **$4.24 net** at $4.99, **$3.39** at $3.99. Requires SBP enrollment.

---

## 6. Free tier and gating matrix

Three rules generate the matrix:

1. **Never gate the core action.** Cleaning is unlimited, everywhere, forever. No usage caps (AI Link Cleaner's mistake), no extension paywalls — the extensions *are* the product.
2. **Never take back what 1.0 shipped free.** Markdown has its own action extension; history search is live; default toggles are live. Clawing any of it back in 1.1 is a bait-and-switch and would harvest 1-star reviews. (This is where v3's matrix gets overridden — §10.)
3. **Gate accumulation and addition, not operation.** History *depth* gates; custom-rule *creation* gates past a small free allowance; new formats arrive gated. Everything a free user already relies on keeps working — and *correctness* (un-breaking an over-cleaned link) is never gated.

| Feature | Status today | Free | Pro |
|---------|--------------|------|-----|
| URL cleaning (app + both extensions) | shipped | ✅ unlimited | — |
| Default parameter removal | shipped | ✅ | — |
| Default parameter toggles | shipped | ✅ (correctness escape hatch — a user must be able to un-break a site) | — |
| Copy as Clean URL | shipped | ✅ | — |
| Copy as Markdown (incl. extension, title fetch) | shipped | ✅ (the viral feature — PKM word-of-mouth is the growth engine) | — |
| History — last **10 days**, searchable | shipped (window is new in 1.1) | ✅ | — |
| History — older than 10 days | 1.1 | ❌ hidden (disclosed, **never deleted**) | ✅ unlimited, searchable |
| Custom parameters — existing ones keep applying | shipped | ✅ (keep-what-you-have) | — |
| Custom parameters — add new | shipped | ✅ first **3** free; ❌ beyond | ✅ unlimited |
| Shortcuts — basic "Clean Clipboard" App Intent | not built | ✅ (distribution lever — Siri / Spotlight / Apple Intelligence reach) | — |
| Copy as HTML / Title+URL | not built | ❌ | ✅ when built |
| History export (CSV/JSON) | not built | ❌ | ✅ when built |
| Domain rules, iCloud sync, widgets, advanced/parameterized Shortcuts | not built | ❌ | ✅ — "all future Pro features" is part of the pitch |

### Why a 10-day window, not an item count

v1 said 25 items, an earlier draft said 50; the time-based reframe is strictly better. v3 set it at 14 days; an interim pass cut it to 7; **1.1 settles at 10** (2026-06-09) — tuned to the validate-WTP + ASO brief (§1), not to maximum squeeze:

- **A window is intuitive and usage-agnostic** — "the last week and a half," not "50 items" with mental math; the 3-links/day and 20-links/day users get the same deal, so heavy use isn't punished.
- **10 clears the habit-formation band.** Habits form in ~7–14 days; at 10 the limit bites *after* most users are hooked, not during (the flaw of the 7-day cut). For an ASO app where early reviews set the trajectory, that gap is rating insurance.
- **A rolling window still produces recurring loss** (something ages out every day) — the one-time-purchase substitute for subscription urgency, just gentler than 7.
- **Levers (§11):** if reviews still show "vanished too fast," **10→14**. Only tighten **10→7** once 1.2 pairs a revenue goal with real Pro features that make the gate feel fair.

**Implementation:** entries older than 10 days are hidden for free users, **not purged** (deviation from v3's 30-day purge — §10), **and the retention is disclosed, never silent** (§9-A). The buried archive is the strongest upgrade pitch we have (*"You've cleaned 312 links. Pro keeps every one of them searchable"*) — but a privacy app must not quietly accumulate a link trail the user can't see, so the app states plainly that hidden entries are kept on-device. The window keys off `HistoryEntry.createdAt`; the surface treatment is §9-A.

### History search stays free

v3 gated search; this doc doesn't. It already shipped free (`HistoryView.searchable`), and a visible-but-disabled search field over 10 days of data is hostile UX for near-zero conversion gain. The Pro value is *unlimited searchable depth* — search within the window is a teaser, search over two years is the product.

### Why 3 free custom rules, not zero (and not one)

v3 gated *all* custom-parameter creation; 1.0 shipped it unlimited-free; an interim pass cut it to one; **1.1 settles at three** (2026-06-09):

- **1.0 users are all grandfathered to Pro (§7), so this never claws anything back** — the allowance only affects users whose *first* install is 1.1+.
- **Not zero, because the privacy mission can't be the wall.** Someone who spots a tracker the catalog misses must never have to *pay to block it* — that gates the one thing rule 1 protects, and on an ASO channel it's a prime 1★ vector ("charging me to protect myself").
- **Three, not one, because the gate has to stay interpretable.** Under a validate-WTP goal (§1), a non-conversion must mean "didn't value unlimited rules," not "got blocked on my second tracker." One bites so early the signal is noise; three lets the casual user — covered by the 85-parameter catalog (7 categories) + 33-entry reference set — effectively never hit it, so the person reaching for a *fourth* rule is genuinely curating (Pro territory) and converts on real value.
- **Levers (§11):** if it still draws resentment, **3→5**; only tighten **3→1** alongside a 1.2 revenue goal.

The first three adds also let the AI advisor (`docs/product/ai-features.md` §5-A) demonstrate value across a couple of suggestions before any wall. Watch `parametersCustomShown` vs `parametersCustomAdded` and review sentiment.

### Why default-parameter toggles stay free (the one thing this pass does *not* gate)

Gating default toggles was considered and **rejected.** A default toggle is the *only* mechanism a user has to stop the catalog over-stripping a parameter a site actually needs — `docs/TODO.md` deliberately rules out any other per-user keep-list. That makes it a **correctness escape hatch, not a power feature**: it sits on the "operation" side of rule 3, alongside cleaning itself, not the "addition/accumulation" side that the tier gates. Gating it would mean *"the app broke your link and you must pay to un-break it"* — the worst review category there is, bought for near-zero conversion gain (tracking parameters are non-functional by nature, so the toggle is rarely reached; rarity means few conversions to capture and outsized harm when it bites). The tier gates *accumulation and addition* (history depth, custom-rule creation); correctness stays free, permanently.

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
| **Monetize** | 1.1 | **The WTP-validation beat (§1).** Timeboxed ~4–6 weeks after 1.0, scoped to IAP only. Pro ships at **$3.99 launch price, clearly marked** ("Launch price — regular $4.99"). 10-day window activates for non-grandfathered users; custom-param creation gates past the 3-rule allowance; 1.0 cohort silently gets Pro. After 30 days: $4.99. |
| **Evaluate** | 1.1 + 60d | Apply §5 decision rules using the funnel data; read it as a WTP signal (§11), rating first. |
| **Expand** | 1.2+ | Each new Pro feature (HTML/Title+URL, export, sync, widgets, Shortcuts) lands behind the existing entitlement — existing Pro owners get everything, the "all future Pro features" promise kept. Only here, with real added-value features and WTP data in hand, does re-tightening the free tier (§6 levers) become well-motivated. Price rises, if ever, apply to new buyers only. |
| **Tip jar** | deferred | v1 wanted it at Month 3. Deferred indefinitely: it complicates the lineup for ~1–3% conversion. Revisit only if users actively ask how to support beyond Pro. |

### Sequencing decision: IAP in 1.0 considered, rejected (2026-06-05)

Shipping with IAP at initial release was evaluated against free-first.

**It would buy:** no clawback constraints on gating (§6 rule 2 vanishes — the matrix is designable from scratch); no grandfathering machinery (§7 deleted); day-one willingness-to-pay signal; conversion data that includes the most engaged cohort instead of excluding it; immunity to 1.1 slippage.

**It would cost:** 1.0 slips behind the Paid Apps agreement, RC integration, and paywall build; the first-ever App Review stacks IAP scrutiny onto an already large surface (two extensions, clipboard access); paying users hit 1.0 bugs (refunds and 1★ instead of bug reports — the Google Maps share issue is still open); one launch beat instead of two; paywall copy written with zero usage data; the "In-App Purchases" listing badge dilutes the free-alternative-to-Clean-Links entry positioning.

**Why free-first wins here:** at realistic quiet-launch volumes (2–5K downloads × 5% × ~$4) the revenue at stake is a few hundred dollars — noise. The decision is *ship weeks sooner with cleaner review optics* vs *skip grandfathering and learn WTP sooner*, and free-first's only structural weakness is gap slippage. So it holds **only with two discipline rules**:

1. **Start the Paid Apps agreement + banking/tax immediately**, in parallel with remaining 1.0 work — zero cost to start, longest lead time, must never be the reason 1.1 waits.
2. **1.1 is IAP-only and timeboxed to ~4–6 weeks after 1.0.** No feature scope rides along. If it slips materially past the timebox, the free cohort grows while revenue sits at $0 — re-read this section and re-decide rather than drift.

---

## 9. Paywall: triggers and experiences

(Answers the implementation plan's "paywall triggers and design" and `docs/TODO.md`'s monetization topic 3. The paywall *sheet* is RevenueCat-hosted so copy/layout stay server-editable; the *triggers and per-surface treatments* below are native SwiftUI and live in the app.)

**The pitch (one sentence):**

> **"LinkClean cleans unlimited URLs, copies as Markdown, and keeps the last ten days of searchable history — free. Pro keeps your history forever, adds more formats and custom rules — $4.99, once."**

### Hard rules (behavioral design, from v3)

1. **Never in the action extensions.** Mid-share interruption poisons the core flow. Every gate lives in the main app. (Consequence: with this matrix the 1.1 extensions need *no* entitlement checks — `EntitlementStore`'s App Group snapshot stays dormant until some future extension-side Pro feature exists.)
2. **Prompt at the moment of value/loss, not before.** No "your oldest links age out tomorrow" pre-warnings, no "your next custom rule is locked" hints before the tap. The paywall appears when the user *reaches for* the gated thing — taps a locked Add, taps into the archive — never in anticipation of it.
3. **One *involuntary* prompt per session, max.** This cap governs surfaces the app raises on the user's behalf. User-initiated opens (the Settings Pro row, a tap on the archive CTA) are always honored — the user asked. A dismissed involuntary prompt stays dismissed until next launch.
4. **Informational, never blocking.** Ambient/inline surfaces (the History archive section, a locked Add row), never a modal ambush on screen entry. The user always reaches a working screen first.
5. **Concrete numbers, not feature lists.** *"You've cleaned 287 links. Pro keeps all of them searchable."* — the user's own counts, pulled live.
6. **"Not now" is always easy to find, and the gate never lies.** No fake urgency, no buried dismiss, no pre-loss nagging. Aged-out history is described as *preserved on-device and reversible* — never as deleted.

### Trigger inventory

| # | Trigger (user action) | Surface | Ships | Check |
|---|---|---|---|---|
| T1 | Tap into the History archive (entries > 10 days) | `HistoryView` ambient "Earlier" section | 1.1 | `pro` |
| T2 | Tap a leftover pill on Home, after the 3 free rules are used | `HomeView.leftoverSection` → confirm step | 1.1 | `pro` |
| T3 | Tap "Add" in Custom Parameters, after the 3 free rules are used | `CustomParametersView` | 1.1 | `pro` |
| T4 | Tap the "LinkClean Pro" row (always available; hosts Restore) | `SettingsView` | 1.1 | `pro` |
| T5 | Accept an AI parameter suggestion past the free allowance | `HomeView` advisor (ai-features §5-A) | 1.2 | `pro` |
| T6 | Tap a locked format (HTML / Title+URL) | format picker | when built | `pro` |
| T7 | Tap Export / toggle iCloud Sync | History / Settings | when built | `pro` |

All triggers open the same paywall sheet (E), contextualized by the trigger that raised it.

### A. History archive — "blur after 10 days," done right (T1)

The matrix (§6) leaves one question open: how do aged-out entries *look*? Three options:

- **Hide entirely** — honest but invisible; the upgrade pull rests on a count the user may never scroll to. Weak.
- **Interleave frosted cells** in the main list (blur every aged cell in place) — strong pull, but it frosts the user's *working set*, nags on every scroll, and is the single ickiest treatment for a privacy app: we captured their link history and now dangle it behind glass. **Reject.**
- **Collapsed, counted, blurred-teaser section** below the active window — **chosen.** Best of both.

Concretely, in `HistoryView` (`@Query(sort: \HistoryEntry.createdAt, order: .reverse)`):

- Entries within 10 days render exactly as today — full `HistoryCellView`, fully interactive, searchable. Pristine.
- For a free user with older entries, a single **"Earlier" section** follows the active list:
  - Header is count-based and live: **"Earlier · 287 links"** (rule 5).
  - 2–3 **blurred teaser rows** — the most recent aged-out entries, blurred hard enough that no URL is legible in a screenshot or screen-share (even the user's own data must not leak through thin frost), non-interactive.
  - One CTA row: **"Unlock your full history — Pro"** → opens the paywall (T1).
- **Disclosure + reversibility in one line.** Subtitle: **"Saved on this device — nothing is deleted. Pro unlocks the full archive."** This is *both* the brand guardrail against a "holding my data hostage" reading *and* the retention disclosure the privacy stance requires (§6: store-and-hide is never silent). It must be present, not optional.
- **Search** for a free user runs over the visible window; if the archive holds matches, show a count-only hint — **"+12 older matches · Pro"** — never blurred result rows. (Keeps "search free within the window, unlimited depth is Pro," §6.)
- Pro/grandfathered users: no section, no blur — the full list, as today.

This **replaces** §9's earlier "inline banner atop History" (a dismissible interruption) with an ambient, self-explanatory surface that needs no dismissal and never nags (§10).

### B. Home leftover pill — gate the action, not the pill (T2)

Today, tapping a "Remaining" pill (`HomeView.leftoverSection` → `leftoverRow`) opens a confirm alert → `HomeViewModel.addLeftoverParameter` → `store.addCustomParameter`. The gate slots in at the confirm step:

- **Within the free allowance** (fewer than 3 custom rules): unchanged — confirm alert → add. Users get to *feel* custom rules persist and work before any wall.
- **After the 3 free rules are used:** the tap opens the **paywall** instead of the confirm alert, contextualized to the param — header **"Remove this tracker — and any you find"**, body **"You've used your 3 free custom rules. Pro removes any tracker, on every link, forever."**
- **Pro/grandfathered:** unchanged — unlimited.
- **The pill never shows a lock at rest.** Home is a privacy surface; a leftover pill that looks paywalled *before* you tap it pre-loss-signals (rule 2) and reads as "pay to protect yourself." The gate reveals itself only on the tap, framed as *free rules used* (a gift spent), not *feature locked* (denial). The param name is never sent to analytics (existing privacy rule).

### C. Custom Parameters in Settings — view free, add gated (T3)

The natural framing is "paywall on tapping Custom Parameters in Settings." Recommendation: **don't gate the row tap — gate the Add.** Free users with existing rules (grandfathered, or their 3 free) must reach the screen to manage and delete *their own data*; the screen itself sells the feature; and "addition, not operation" (§6 rule 3) is the honest line.

- Tapping the **Custom Parameters** row opens `CustomParametersView` — **free**. Fires `parametersCustomShown`.
- Existing rules list and apply normally (keep-what-you-have).
- The **Add** affordance is state-aware:
  - Within allowance: normal add field, with a quiet counter — **"2 of 3 free rules."**
  - Allowance used (3 rules exist): the Add row carries a **lock glyph + "Pro · unlimited custom rules,"** reading **"3 of 3 free rules used."** Tap → paywall (T3). Here a persistent lock *is* right (unlike Home): this is a deliberate management screen, so signaling the boundary is honest, not interruptive.

### D. Settings "LinkClean Pro" row — the always-open door (T4)

A persistent `SettingsView` row, state-aware:

- Free: **"Unlock Pro — $3.99 · launch price"** (→ "$4.99" after the launch window) → paywall.
- Pro/grandfathered: **"LinkClean Pro ✓"** with a quiet thank-you; no purchase CTA.
- **Restore Purchases** is always present here regardless of state — App Review requires it reachable without buying. No urgency, no nag; this is the browse-anytime entrance.

### E. The paywall sheet (shared surface, RevenueCat-hosted)

- **One sheet, contextual header.** The body is constant; the top line adapts to the trigger (T1 → *"Keep all 287 links searchable"*; T2/T3 → *"Remove any tracker you find"*). Pass the trigger as the RevenueCat offering/placement context.
- **Value order leads universal, AI last.** Headline = the one-sentence pitch (top of §9). Bullets: unlimited searchable history → custom rules → formats / export / sync → *"Plus, on supported devices: on-device suggestions and tagging"* (ai-features §7 — AI never headlines; device-gated capability up top invites "doesn't work on my phone" 1★).
- **Price is launch-aware and honest:** *"$3.99 · launch price — regular $4.99,"* no fake countdown.
- **One primary CTA; "Not now" prominent; Restore inline.** Links to **Terms of Use** + **Privacy Policy** (Apple requires an EULA/terms once IAP ships — the open `docs/TODO.md` 1.1 item).
- **Family Sharing** badge shown (the non-consumable is Family-shared, §4).

### Funnel analytics

The reserved funnel events, to be added to `AnalyticsEvent` under the `Feature.Subject.verbPast` convention (`docs/plans/analytics.md`) when 1.1 is built. **Privacy rule holds:** a fixed `trigger` enum only — never a URL or a parameter name.

- `Paywall.Screen.shown(trigger:)` — `trigger ∈ {historyArchive, customParamHome, customParamSettings, settingsRow, advisorAccept, formatPicker, export, sync}`. Tells you *which gate converts* (§11).
- `Pro.Purchase.started` / `.completed` / `.failed(reason:)`
- `Pro.Purchase.restored`
- Joins the existing `parametersCustomShown` → (T2/T3) `Paywall.Screen.shown(customParam*)` → `Pro.Purchase.completed` path, and the ai-features §9 `paramSuggestionShown → Paywall.Screen.shown(advisorAccept)` path.

---

## 10. Deviations from the raw docs

Traceability for every place this doc overrides v1/v3 (and, in the lower rows, the 2026-06-09 revalidation + free-tier calibration). The 14→7 / 5→1 tightening these supersede was an interim step on the same day — only the final 10-day / 3-rule calibration is operative.

| Topic | v1 said | v3 said | This doc | Why |
|-------|---------|---------|----------|-----|
| Price | $2.99 ($4.99 "creates deliberation") | $4.99, launch $3.99 | **v3** | Later iteration; value-based math; built-in fallback to $3.99 if conversion <4% addresses v1's risk |
| History limit | 25 items | 14 days | **10 days** (calibrated 2026-06-09) | Time-based + usage-agnostic; tuned to validate-WTP + ASO (§1) — 10 clears the habit-formation band (fair gate, protected rating) where 7 bit too early; levers 10↔14 / 10→7-only-with-1.2-revenue-goal |
| Hidden-history purge | preserve ("Your history is there. Unlock it.") | purge after 30 days | **v1 — keep, and disclose** | The archive *is* the upgrade incentive; storage is trivial; retention is disclosed in-app, never silent (§6/§9-A) |
| Formats | all free (marketing engine) | Markdown free; HTML, Title+URL Pro | **v3** | Hybrid keeps the viral PKM loop and still differentiates Pro; also forced — Markdown already shipped as a free extension |
| History search | Pro | Pro | **Free** (within window) | Already shipped free in 1.0; disabled search over 10 days is hostile for no gain; Pro = unlimited *depth* |
| Default parameter toggles | (free) | Pro | **Free** | Correctness escape hatch, not a power feature — the *only* way to stop over-stripping (§6); on the "operation" side of rule 3; gating it risks "app broke a site and won't let me fix it" reviews for near-zero gain |
| Launch phasing | 4 weeks free → Pro | 2-week soft launch → Pro | **1.0 free → 1.1 Pro** | Version-based reality replaces calendar choreography; same intent (reviews before monetization) |
| Grandfathering mechanism | n/a | `firstLaunchDate` + remote flag | **`originalApplicationVersion`** | Survives reinstall, cross-device, zero 1.0 work, lives at the existing RC service boundary |
| Tip jar | add at Month 3 | absent | **Deferred indefinitely** | Lineup complexity for negligible revenue at this scale |
| Revenue projections | month-by-month $38K Y1 | $45–107K Y1 | **Per-10K model only (§11)** | Both were anchored to a Feb 2026 download plan that no longer exists; downloads are the unknowable input |
| App name | LinkKit | LinkKit | **LinkClean** | Product renamed |
| v3's "CleanLink $24.99" comparisons | — | cited | **Dropped** | Not in v1's researched table; unverifiable |
| Custom-param creation | (free, unlimited) | Pro (zero free) | **3 free, then Pro** (§6, calibrated 2026-06-09) | Not zero (privacy mission can't be the wall; an ASO 1★ vector); not one (keeps the WTP gate interpretable — a "no" means "didn't value depth," not "annoyed"); 1.0 grandfathered; levers 3↔5 / 3→1-only-with-1.2-revenue-goal |
| Basic Shortcuts / App Intents | — | Pro | **Free (basic), Pro (advanced)** (§6) | App Intents is a Siri / Spotlight / Apple-Intelligence *distribution* surface; a free basic "Clean Clipboard" intent is cheap top-of-funnel reach |
| No-subscription precommitment | — | — | **Softened "ever" → "not primary, not at 1.1"** (§12) | Keep the marketing line (a weapon vs CleanSend) without carving the product door shut on a future optional supporter tier |
| History paywall surface | inline banner | inline banner | **Ambient blurred "Earlier" archive section** (§9-A) | Self-explanatory, non-nagging, honest about preservation — beats a dismissible banner |
| 1.1 monetization goal | (implicit revenue) | (implicit revenue) | **Validate WTP, not maximize revenue** (§1) | Pre-launch + ASO-driven: 1.1 measures *whether* people pay; gates tuned for an interpretable signal and a protected rating, not conversion squeeze |
| Free-user history retention | (kept, framed "unlock it") | purge | **Store-and-hide *with disclosure*** (§6/§9-A) | Keeps the upgrade pitch without a privacy app silently accumulating a hidden link trail |

---

## 11. Revenue model

Downloads are the input we can't predict (the Feb 2026 forecasts assumed a marketing plan that's moot). Conversion and price we control, so model **per 10,000 post-1.1 downloads**:

| Conversion | Pro sales | Net @ $4.24 |
|------------|-----------|--------------|
| 3% (downside) | 300 | $1,272 |
| 5% (base — industry norm for well-executed freemium utilities) | 500 | $2,120 |
| 7% (upside) | 700 | $2,968 |

The free tier (§6: 10-day window, 3 free custom rules) is **calibrated for the validate-WTP beat on an ASO channel (§1), not for revenue maximization** — fair gates so a non-conversion is interpretable ("didn't value Pro," not "got annoyed"), and so early reviews stay clean. The point of 1.1 is to learn *whether* people pay and *which gate* converts; squeezing conversion comes in 1.2+ with real Pro features. The §6 levers (10↔14 days, 3↔5 rules) keep the calibration adjustable from review signal.

Adjustments: launch-price sales net $3.39; regional-tier sales net ~$1.7–2.5; blended net realistically **~$3.90–4.10**. At v3's (optimistic) 360K year-one downloads and 5%, that's ~$70K; at a more sober 50–100K, **$10–20K** — validates a solo product, funds the developer account and infrastructure, and prices in zero growth from Pro features still unbuilt.

**The real ceiling is the promise, not the price.** *"All future Pro features behind the one entitlement, forever"* (§8 Expand) is the pitch's backbone *and* its constraint: HTML/Title+URL, export, sync, widgets, Shortcuts, and the entire on-device-AI roadmap (ai-features §5) are all pre-sold at a single sub-$5 capture, with no expansion revenue from existing owners. That is survivable only because every gated capability is **cheap to run** — on-device AI has zero marginal cost (Foundation Models, no API key), sync rides free CloudKit. The model breaks the day a roadmap item carries real per-use cost; none currently does, which is *why* the promise is safe to make. Standing guidance: if a future Pro feature ever needs ongoing spend, it is a **new product** (a separate one-time pack), not a free addition to the existing entitlement — and that is the only circumstance that reopens §12's subscription question.

**Metrics for 1.1 — read it as a WTP experiment, rating first** (funnel events reserved in §9 and the analytics plan — `Paywall.Screen.shown(trigger:)`, `Pro.Purchase.started/completed/failed/restored`):

- **Rating (the binding ASO constraint).** Target ≥ 4.7; any rise in "why is my history gone" / "charging to block a tracker" reviews means a gate is misjudged — loosen via the §6 levers *before* optimizing conversion.
- **Pro conversion rate** (target ≥ 5%; floor 4%) — read as a *WTP signal* at 1.1, not a revenue KPI.
- `Paywall.Screen.shown → Pro.Purchase.completed` **by trigger** — which gate actually converts (the 10-day archive and the 3-rule gate are the two to watch).
- **Install → purchase latency** (validates the 10-day window; if the median sits well inside 10 days the window is fine; if short latency pairs with "vanished too fast" reviews, loosen 10→14 before touching price).

---

## 12. What NOT to do (standing constraints)

- **No subscription at 1.1, and never as the primary model** — and keep saying "no subscription" in marketing; the line is a weapon against CleanSend. (Softened from "ever": don't carve the door shut on a future *optional* supporter tier — keeping it cracked costs nothing but the word, the marketing line stays true for the core product regardless, and §11 names the one scenario that would reopen the question.)
- **No usage caps on cleaning.** The core action is unlimited, always.
- **Never gate correctness.** Default-parameter toggles — the only way to un-break an over-cleaned link — stay free no matter how the tier tightens (§6).
- **Disclose retention, never silent.** The hidden history archive is retained on-device *and the app says so* (§9-A); a privacy app must not quietly accumulate a link trail the user can't see.
- **No paywall in the share/action extensions.** The extension is the product.
- **Never gate Markdown retroactively.** It's the growth engine and it shipped free.
- **Never delete a free user's hidden history.** It's the upgrade incentive and their data.
- **Nothing above $5.99**, and no second "Pro+" tier alongside — one entitlement, growing forever (the only exception is §11's separate-product case for a genuinely costly future capability).
- **No ads.** A privacy app with ads is a self-refuting product.
- **No dark patterns at the paywall** — no fake urgency, no buried dismiss, no pre-loss nagging, no frosting the user's working set (§9-A).

---

## 13. Unblocked next steps

1. **ASC (Ken, start now — parallel with remaining 1.0 work):** Paid Apps agreement + banking/tax (longest lead) → create one non-consumable (`linkclean_pro_lifetime`) at the §5 price points → RC dashboard entitlement `pro` + default offering + paywall — per implementation plan Phase A.
2. **Code (Claude):** implementation plan Phases B–C, plus the §7 grandfather mapping, the §9 triggers/surfaces (history archive partition at 10 days, the 3-rule custom-param allowance, the four 1.1 trigger sites, the retention-disclosure copy), and the reserved funnel events.
3. **Before 1.1 ships:** re-verify the §2 competitive snapshot (it's from Feb 2026) — pricing moves; the $4.99 case assumes Trackless Links still anchors $5.99.
