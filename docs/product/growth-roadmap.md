# LinkClean Growth Roadmap

> **Status: partially-shipped — 2026-06-25 (last sync).** Originally proposed 2026-06-10. **Update 2026-06-25:** 1.2.0 (2026-06-18) and 1.2.1 (2026-06-23) are now LIVE — **E4 short-link expansion shipped** (free for all tiers), **ai-C title refinement slipped** (deferred pending an FM-appetite call; the ai-A advisor was hidden behind a DEBUG flag in 1.2.1). §9 and §10 are reconciled to this; the inline "1.2" pins in §1/§5/§6/§7 predate it and the §9 table is the source of truth. Nothing below is committed to a release; the sequencing in §9 is the recommendation and the open calls are collected in §10.
> Scope: **how the product grows after launch** — engine depth, OS surfaces, visible value, localization, and platform expansion. This doc composes with, and does not restate, the three decided strategies: [iap-strategy.md](../strategy/iap-strategy.md) ("iap §n") owns pricing/gating, [ai-features.md](ai-features.md) ("ai §n") owns the AI beats, [kpis.md](../strategy/kpis.md) owns measurement. Where this doc assigns Free/Pro, it applies iap §6's three rules; deviations are flagged, not smuggled.
> Sources: codebase inventory 2026-06-10 (`URLCleaner.swift`, `TrackingParameters.swift`, `ProGate.swift`, extension targets, `Localizable.xcstrings`), plus the docs above and [docs/TODO.md](../TODO.md).

> **⚠️ 1.1 ate 1.2.** Between proposal-time (2026-06-10) and the 1.1.0 release (LIVE 2026-06-16) the **entire originally-planned 1.2 release** got pulled forward into 1.1.0 — ai-A advisor, V2 dashboard, V3 share card, German localization, and P1 formats (the "first real Pro beat") all shipped *with* 1.1's S1/E1/E2/V1/ja set, plus **QR scan + generate** which wasn't on the roadmap at all (Ken rejected E3 multi-link in favour). §5 / §6 / §7 / §9 below still show the original "1.2" pin on those items so the planning trail stays readable; inline ✅ markers and parenthetical *(shipped 1.1.0)* notes flag what actually landed where. The next release window is **whatever-becomes-1.2** (small backlog: ai-C smart titles + E4 short-link expansion per [ROADMAP.md](../ROADMAP.md)).

---

## 1. Context (June 2026)

- **Launch collapsed the 1.0→1.1 choreography.** The withdrawn free-only build never entered review; **1.0.0 (10) ships with IAP on day one**. iap §8's "1.1 = monetize" beat is therefore already inside 1.0.0, and version numbers below renumber accordingly: the next feature release is **1.1**, and ai §8's "first AI beat at 1.2" survives unchanged.
- **What shipped:** query-parameter stripping (85-param catalog, 7 categories, host scoping), two share extensions (Clean URL, Clean Markdown Link), searchable history (7-day free window), custom rules (1 free), leftover-parameter pills, onboarding + extension guide, Pro paywall (T1–T4), review gate, TelemetryDeck event layer with catalog-gap telemetry.
- **What the engine does NOT do yet:** unwrap redirect/wrapper URLs, touch fragments, expand short links, normalize hosts, or clean more than the first link in shared text (`ActionExtensionViewController` takes the first `NSDataDetector` match).
- **No OS surface beyond the share sheet:** no App Intents, widgets, Control Center controls, Safari extension, or clipboard automation. English only. No user-facing stats anywhere (the only persistent counter is `ReviewGate`'s).
- **WWDC 2026 is this week (June 8–12).** Per ai §11, re-verify Foundation Models *and* the App Intents / controls surface APIs against announcements before building §4.
- *Drift flag:* ai §8 says "the app stays iOS 18"; CLAUDE.md says the floor is **iOS 26+**. This doc assumes iOS 26+, which removes every `#available` dance for controls, interactive widgets, and Foundation Models.

### The strategy frame

iap §1's thesis stands: LinkClean cannot out-free Clean Links as a tracker-stripper; it wins as a **link productivity tool** with a privacy-absolute architecture. Growth therefore has four independent levers, each a section below:

1. **Deeper engine** (§3) — close the gap between "strips parameters" and what "clean link" means to users.
2. **More surfaces** (§4) — meet links where they live; every surface is an acquisition + retention loop.
3. **Visible value** (§5) — give the silent utility a voice; the user who can *see* 1,200 removed trackers talks about the app.
4. **More markets** (§7) — localization multiplies ASO surface area at near-zero product risk.

The AI beats (ai §5 A–E) thread through these; §6 maps them in without duplicating that doc.

**Inherited constraints (binding):** never gate the core action; never claw back; gate addition/accumulation, not operation; no extension paywalls; no subscription; nothing above $5.99, one entitlement growing forever; every gated capability must be free to run (iap §11/§12). On-device only for AI; determinism for the core action (ai §3). No per-user keep-list (TODO, decided 2026-06-08) — over-cleaning fixes belong in the catalog.

---

## 2. North star and what each lever moves

North star (kpis §0): **exports per active user per week**. Lever → KPI mapping, so every §9 release has a falsifiable goal:

| Lever | Moves | KPI |
|---|---|---|
| Engine depth | export quality → trust → retention | kpis §8 retention, review rating |
| OS surfaces | clean opportunities per day | kpis §0 north star, §6 surface mix |
| Visible value | D30 retention + word of mouth | kpis §8, §1 installs (organic) |
| Localization | installs in new storefronts | kpis §1 by storefront |
| Pro stack (§8) | conversion *after* WTP validated | kpis §15/§16 |

---

## 3. Engine depth — close the "clean" gap

Today `URLCleaner.clean` is query-parameter filtering. The items below are ranked; the first is the flagship.

| # | Upgrade | What | Free/Pro | Effort | Target |
|---|---|---|---|---|---|
| E1 ⭐ | **Offline redirect unwrapping** | Extract the destination from known wrapper URLs — `google.com/url?q=`, `l.facebook.com/l.php?u=`, `l.instagram.com/?u=`, `*.safelinks.protection.outlook.com/?url=`, `steamcommunity.com/linkfilter/`, `duckduckgo.com/l/?uddg=`, `vk.com/away.php` — then **re-clean the inner URL recursively**. Zero network: the destination is already in the query string. | ✅ Free | M | 1.1 |
| E2 | **Fragment cleaning** | Strip tracking params that ride the fragment (`#utm_…`) and, behind a default-on toggle, Google's `#:~:text=` scroll-to-text fragments. | ✅ Free | S | 1.1 |
| E3 | **Multi-link text mode** | Clean *every* link in pasted/shared text in place (full `NSDataDetector` sweep), preserving surrounding prose. Today only the first URL survives extraction. | ✅ Free | M | 1.3 |
| E4 | **Short-link expansion** | Resolve `bit.ly`/`t.co`-class links via a network round-trip, then clean the destination. Opt-in toggle with honest copy (the request reaches the shortener), plus "preview destination before opening" as the safety frame. | ❌ Pro | M | 1.4+ |
| E5 | **Host normalization** | Optional preferred-domain rewrites (`google.com/amp/…` → canonical, `m.youtube.com` → `youtube.com`). Off by default; some rewrites are contested. | ❌ Pro (rides "domain rules", iap §6) | S | with domain rules |

**Free/Pro reasoning.** E1/E2 are what "clean this link" *means* — they sit on the operation side of iap §6 rule 3, and a wrapper link that comes out still wrapped reads as the app failing. E1 in particular is table stakes vs. competing cleaners and the single biggest functional answer to "why this over Clean Links." E4 is the one engine item that costs a network call and serves the researcher persona — addition, not operation, so it gates cleanly; it is also the only item here that touches the network, so it must stay opt-in regardless of tier. E3 is free because it strengthens the Markdown/PKM growth engine (kpis §11): cleaning every link in a pasted note is exactly the note-taker's workflow.

**Catalog operations (standing, not a release item).** The catalog-gap telemetry (Tier 0/1, `referenceMatches`) already identifies the novel tail — close the loop with a monthly review that promotes winners into `TrackingParameters.swift`, sourced from public tracker lists per ai §6 (curated, never model-generated). Say it in release notes ("now catches N new trackers") so catalog updates market themselves. A remotely-fetched catalog would decouple updates from App Review but adds a phone-home fetch to a privacy app; **stay with in-release catalog shipping** until update latency demonstrably hurts.

---

## 4. OS surfaces — meet links where they live

The share sheet is the only entry point today, and extension adoption is the funnel's leakiest joint (kpis §6 calls surface mix the load-bearing diagnostic). Each surface below is a new loop, ordered by leverage-per-effort.

### S1 ⭐ App Intents (1.1) — one framework, five surfaces

A `CleanLinkIntent` (URL/text in → cleaned URL out) and a `CleanClipboardIntent` (clean the pasteboard in place) light up: **Shortcuts automations, the Action button, Spotlight, Siri / Apple Intelligence, and interactive widget + Control Center buttons.** The killer flow is *copy anywhere → tap the Control Center control → cleaned link is in the clipboard* — faster than the share sheet itself.

Placement per the decided matrix (iap §6): the **basic Clean Clipboard intent is free** — it's the distribution lever, already so decided. This doc adds one recommendation and flags it as a deviation to ratify (§10): the **Control Center control and a single-button Lock Screen/Home widget that merely *run* the free intent should also be free.** A lock icon inside Control Center on a "privacy utility is free" product is self-defeating; what stays Pro per the matrix is *configurable* widgets (multi-action, stats faces) and *parameterized* Shortcuts (clean-with-specific-rule-set, batch).

This is also ai §5-E's prerequisite ordering (E before D) satisfied early, and it future-proofs visibility to Apple Intelligence. Effort M.

### S2 Safari Web Extension (1.3 v1, auto-clean later)

Safari is where dirty links are born. **v1 (free):** toolbar popup that cleans the current page's URL — Copy / Share / Copy as Markdown. Same kit, same catalog, all local. **v2 (Pro, 1.4+):** auto-strip known parameters on navigation via `declarativeNetRequest` redirect rules — needs a spike on iOS Safari's `regexSubstitution` limits before it's promised anywhere. v1 free / v2 Pro maps exactly onto operation vs. automation (iap §6 rule 3). Effort: v1 M, v2 L + spike.

### S3 Clipboard ergonomics (with S1)

The Auto-paste toggle already exists; S1's clipboard intent supersedes the rest of this space. Explicitly **not** doing pasteboard polling/auto-clean in the background — iOS pasteboard privacy UX would make a privacy app look like a snoop. The control *is* the clipboard story.

### Non-surfaces (considered, rejected for now)

Custom keyboard (permission horror for a privacy brand), watchOS (no link workflow), Messages app extension (share sheet already covers it). Revisit only on user pull.

---

## 5. Visible value — stats, share card, recap

The app does its job silently and gives users nothing to talk about. Deterministic counters fix that (real data, per ai §6's anti-option rationale — counts, not invented scores).

- ✅ **V1 — Local stats counters** *(shipped 1.1.0).* App Group-persisted aggregates, independent of History so the 7-day free window never erases them: total cleans, total parameters removed, removals by category (`removedKindIDs` already carries this), top sites (host only — same granularity the telemetry already uses).
- ✅ **V2 — Stats dashboard** *(originally 1.2; shipped 1.1.0).* "1,247 trackers removed · top site youtube.com · most common utm_source." A screen, not a tab — reachable from Settings and a Home badge tap. **Free**: this is operation visibility, and like Markdown it's a growth engine, not a power feature. Lever if needed later: per-site/per-category deep slices go Pro; the headline numbers never do.
- ✅ **V3 — Shareable privacy card** *(originally 1.2; shipped 1.1.0).* Rendered image of the user's stats for posting. This is the on-brand growth mechanic — explicitly **instead of** appending any "cleaned with LinkClean" suffix to shared URLs, which would be adding tracking to a tracker remover. Doubles as instant App Store screenshot. Pulled forward from 1.2 alongside V2 + ai-A to make 1.1's "What's New" the cohesive launch reel (1.0.0's release showed no notes; 1.1.0's is the first one users see).
- **V4 — Opt-in monthly recap (1.3).** Local notification, "Your June privacy report." Local-only, opt-in from the dashboard (never a permission prompt at onboarding), one per month. One of the few re-engagement hooks a no-account utility can run without betraying itself.

---

## 6. The AI beats (owned by ai-features.md — mapping only)

No changes proposed to ai §5/§8; the renumbering note (§1) keeps its targets intact:

| ai § | Feature | Free/Pro (ai §7) | Lands |
|---|---|---|---|
| A ⭐ | Unknown-parameter advisor (heuristic + FM tiers) | suggestion free / acting hits the custom-rule gate | ✅ **shipped 1.1.0** (originally 1.2; pulled forward with V2/V3) — the on-device-intelligence marketing beat |
| C | Title refinement | Pro, bundled with formats | 1.2 (with the next round of formats) if the latency spike passes; else in-app only. Note: P1 formats (template engine + picker) already shipped in 1.1.0 *without* ai-C — the AI title beat is the remaining 1.2-eligible piece. |
| B | History auto-tagging | Pro | 1.3 |
| E | App Intents (no model) | basic free / advanced Pro | ✅ **shipped 1.1.0** (§4 S1) — satisfies "E before D" |
| D | NL history search | Pro | 1.4+ (needs B) |

Synergy worth naming: the advisor (A) fed the custom-rule funnel (kpis §9, premium candidate #1), and S1's Apple Intelligence visibility plus A's on-device story made "intelligent *and* private" the coherent 1.1.0 narrative (it was originally meant to land at 1.2).

---

## 7. Markets — localization and the ASO loop

TODO already sanctions this ("translations come later"); the identifier-key catalog infrastructure shipped ready (the kit's no-`manual`-entries constraint is solved). Order by storefront leverage:

1. ✅ **Japanese (1.1).** Shipped 1.1.0. Home market, strong utility-app culture, founder can QA the translation natively.
2. ✅ **German (1.1).** Shipped 1.1.0 (originally pinned to 1.2; pulled forward — Wave-1.5 localization committed `2999f41` 2026-06-13). The most privacy-sensitive major storefront — the positioning translates literally. *Native review still pending — du/Sie tone decision standing.*
3. **French + Spanish (1.3).** Volume.
4. Re-evaluate from kpis §1 by-storefront data before going wider (zh-Hans, pt-BR, ko are the usual next tier).

Each locale is also an **ASO multiplier**: a separate keyword field and screenshot set per storefront via the existing fastlane + composer pipeline. Standing loop regardless of locale: quarterly keyword refresh, Product Page Optimization tests on screenshots, and the post-launch share-sheet screenshot TODO already on file. ⚠️ **The app binary now ships ja+de strings as of 1.1.0, but `fastlane/Deliverfile` still pins ASC metadata to `en-US` only** — the marketing listing (description, keywords, screenshots) is en-US even on the Japanese / German storefront. Adding ja-JP and de-DE metadata folders is the natural next ASO move; it's lighter weight than another binary release. The `linkclean.app` domain decision is ✅ closed (bought 2026-06-16, LP + landing site LIVE; see [monorepo-and-landing.md](../strategy/monorepo-and-landing.md)).

---

## 8. The Pro stack — what the entitlement grows into

iap §11 is explicit: 1.0's gates validate WTP; **conversion-squeezing waits for real Pro features.** This doc schedules them (all behind the one entitlement, all free-to-run per the §11 ceiling rule):

| Pro feature | Source | Lands |
|---|---|---|
| ✅ Copy as you want — link-format template engine + in-extension picker | iap §6 "when built" | **shipped 1.1.0** (originally 1.2 "first real Pro beat"; pulled forward — the actual first Pro beat). ai-C smart-title refinement is the remaining 1.2 piece. |
| iCloud sync — custom rules, toggles, history (CloudKit private DB; "your data in *your* iCloud, we never see it") | iap §6 | **1.3** — the headline Pro release |
| History export (CSV/JSON) | iap §6 | 1.3 (small, rides along) |
| History auto-tagging (ai-B) | ai §5 | 1.3 |
| Domain rules (+ E5 normalization) | iap §6 | 1.4+ |
| Advanced/parameterized Shortcuts, configurable widgets | iap §6 | 1.4+ |
| Safari auto-clean (S2 v2), short-link expansion (E4) | this doc | 1.4+ |
| NL history search (ai-D) | ai §5 | 1.4+ |

**Mac (2.0 horizon).** A menu-bar clipboard cleaner is a proven macOS category and the strongest "one purchase, growing forever" proof available — universal purchase carries the existing entitlement at no new price. Prerequisite: LinkCleanKit currently imports UIKit (CLAUDE.md: `swift test` fails on macOS), so a platform-conditional pass on the kit comes first. Park at 2.0; do the kit decoupling opportunistically earlier if a refactor touches those files anyway.

**Two flags, not proposals:** Family Sharing is deliberately OFF — revisit at 1.3 when sync makes multi-device households the actual audience. And the $4.99 → $5.99 headroom (iap §12 ceiling) is the lever to pull when the 1.3 stack ships, for new buyers only — never retroactive mechanics.

---

## 9. Sequencing

| Release | Theme | Contents | The falsifiable goal |
|---|---|---|---|
| ✅ **1.1** *(LIVE 2026-06-16)* | *Clean from anywhere, intelligently, visibly* | S1 App Intents (intent + control + button widget), E1 unwrapping, E2 fragments, V1 counters, V2 dashboard, V3 share card, ai-A advisor, P1 Copy-as-you-want template engine + picker, **QR scan + generate** (new, not in original plan), 🇯🇵 ja + 🇩🇪 de, the `linkclean.app` domain + landing site | Surface mix (kpis §6) ≥ 15% intent/control cleans by D60; first conversion read vs. iap §11's 5% base; rating holds ≥ 4.7; card shares appear in the wild |
| ✅ **1.2** *(LIVE: 1.2.0 2026-06-18, 1.2.1 2026-06-23)* | *Deeper unwrap (shipped); smarter titles (slipped)* | ✅ **E4 short-link expansion** (1.2.0, free for all tiers, opt-in); **ai-C title refinement deferred** — did not ship, pending an FM-appetite call after the ai-A advisor was hidden behind a DEBUG flag in 1.2.1 | E4 cleans-per-session lift (ai-C unmeasured — not shipped) |
| **1.3** | *Your links, everywhere, organized* | iCloud sync, export, ai-B tagging, S2 Safari v1, V4 recap, 🇫🇷🇪🇸 | Conversion ≥ 5% sustained; D30 (kpis §8) lifts vs. 1.1 cohort |
| **1.4+** | *Power* | ai-D NL search, advanced Shortcuts/widgets, domain rules + E5, S2 v2 auto-clean | Pro-user behavior split (kpis §20) justifies continued Pro investment |
| **2.0** | *Platform* | Mac menu-bar app (after kit decoupling), price-headroom review | New-platform installs without new entitlement cost |

Why this collapsed: with 1.0.0 holding a fix-build slot in review, the team kept shipping into the unmerged `feature/redirect-unwrapping` branch and the parallel Pro/AI/locale streams. By the time 1.0.0 went live (2026-06-15) the bundle was already 1.2-shaped, so 1.1 became "Clean from anywhere + Intelligent + Visible + First Pro beat + multi-locale" in one cut, and 1.0.0's silent What's New made 1.1.0's notes the first thing real users read. **Reading the original "1.1 grows the base the 1.2 paywall meets" sequencing now: that sequencing collapsed — the paywall (P1 formats) shipped on day one of 1.1. Net effect: faster conversion read, smaller-than-planned 1.2 backlog, sync (1.3) still the headline conversion driver.**

---

## 10. Open decisions (ratify before 1.1 scoping)

1. **Control Center control + single-button widget: free?** (§4 S1 — recommended yes; deviation from a literal reading of iap §6's "widgets → Pro".)
2. ✅ **E4 short-link expansion** — **Decided & shipped (1.2.0, 2026-06-18): free for all tiers** (not Pro), opt-in, default off — the one feature that reaches the network. The "is an opt-in network feature acceptable at all?" question resolved **yes**, with honest in-Settings copy. (Note: this is the one §3 deviation — E4 was pinned ❌ Pro there; the ship decision overrode it to free, judging expansion table-stakes rather than an add-on.)
3. **Safari v1 free / v2 Pro split.** (§4 S2 — recommended as stated.)
4. **Localization order confirm** (ja → de → fr/es) and translation sourcing (founder-QA'd ja; paid translation for the rest).
5. ✅ **`linkclean.app` domain** — **Decided yes 2026-06-16**: domain bought, DNS on Cloudflare, landing site LIVE at [`linkclean.app`](https://linkclean.app/) with home + `/trackers/` + `/guides/` + `/learn/` clusters. See [monorepo-and-landing.md](../strategy/monorepo-and-landing.md) and [seo-content-plan.md](../strategy/seo-content-plan.md).
6. **Family Sharing revisit at 1.3** (carried flag, iap §5 context).
7. Per iap §13.3: **re-verify the Feb 2026 competitive snapshot** — ⚠️ **still outstanding as of 2026-06-25 (now ~4 months stale)**; it predates launch; Clean Links' and Trackless Links' current state should sanity-check E1's "table stakes" claim and the price headroom note.

## 11. Measurement note

Every new surface gets an adoption event in the existing taxonomy style (`actionCleanSucceeded` is the precedent): intent runs, control taps, Safari-ext cleans, card shares, locale-sliced funnels. kpis §6 (surface mix) becomes the primary read on §4; kpis §15/§16 on §8. Run the analytics-audit pass per release before build, not after ship.
