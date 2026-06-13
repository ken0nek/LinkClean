# LinkClean — Growth & Promotion Strategy

> **Status: proposed — 2026-06-13.** The go-to-market / demand-generation layer: **how people discover, choose, and recommend LinkClean** across ASO, SEO, LLMO, paid, the landing page, and the "wow" features that market themselves. Complements — does not restate — the product-growth levers in [growth-roadmap.md](../product/growth-roadmap.md) (engine/surfaces/visible-value/markets) and the measurement layer in [kpis.md](kpis.md).
> **Scope:** acquisition + conversion + word-of-mouth. The *product* roadmap, *pricing*, and *what-we-measure* live in their own docs and are referenced, not duplicated.
> **Builds on:** [iap-strategy.md](iap-strategy.md) §1 (positioning), [competitor-clean-links.md](competitor-clean-links.md) (the competitive read), [growth-roadmap.md](../product/growth-roadmap.md) §5/§7 (visible value + markets), [kpis.md](kpis.md) §0–§17 (funnel + north star), [app-store-metadata.md](../release/app-store-metadata.md) (current ASO copy).
> **Frame:** indie / bootstrapped / privacy-absolute. The brand forbids the usual growth tech (no ad SDKs, no pixel retargeting, no data resale) — so the engine is **organic-compounding first** (ASO · SEO · LLMO · community), with **paid as a measured accelerant** only once conversion is proven. Cost ≈ 0 (kpis §2), so every channel is judged on **cost-per-Pro-conversion**, not cost-per-install.

---

## 0. The growth thesis

**Positioning (from [iap-strategy.md](iap-strategy.md) §1):** LinkClean cannot win as a cheaper/free tracker-stripper — the market leader **Clean Links is subsidized-free** ([competitor-clean-links.md](competitor-clean-links.md) §1.1). It wins as a **link-productivity tool with a privacy-absolute architecture**, for people who *work with links*: note-takers, researchers, developers, bloggers (the PKM/Obsidian/Notion/Shortcuts crowd).

**Three wedges** — every channel below leads with one or more:

| Wedge | The claim | What it's *not* (vs Clean Links) |
|---|---|---|
| **Productivity** | Markdown/format export, searchable history, custom rules, on-device AI advisor | Clean Links has none of these (no format export, markets "no history") |
| **Privacy-absolute** | 100% on-device, no account, **nothing leaves your phone**, auditable | Clean Links' no-cookies/no-log internals are un-audited vendor claims |
| **Polish** | Liquid Glass design; calm, transparent UX | Utility-first competitor |

**North star ([kpis.md](kpis.md) §0): exports per active user / week.** Acquisition (this doc) fills the top; activation (first clean → first export) and the wow loop compound the middle; Pro conversion (kpis §15) monetizes. Growth = *more of the right users × more value realized per user.*

**Channel philosophy:** compounding-organic channels (ASO/SEO/LLMO/community/share-loop) build a moat that a subsidized-free competitor with a thin community (49 ratings, dev-only subreddit) is *beatable* on. Paid buys speed, not a moat — use it to validate, then scale only on proven CPA < LTV.

---

## 1. ASO — the primary acquisition channel

For an indie iOS app, ASO is the highest-leverage, lowest-cost, highest-intent channel — searchers in the App Store already want a cleaner. **Current copy** ([app-store-metadata.md](../release/app-store-metadata.md)): name **`LinkClean – URL Cleaner`**, subtitle **"Remove trackers from links"**, keywords `utm,fbclid,gclid,privacy,tracking,share,markdown,copy,paste,parameter,query,redirect,utm_source`, categories **Utilities / Productivity**.

### 1.1 Keyword strategy — target the long tail, not the head
Don't fight Clean Links for the head term "url cleaner." Own the clusters they *don't* serve and the high-intent literals:

| Cluster | Example terms | Why |
|---|---|---|
| **Literal trackers** ⭐ | `utm_source`, `fbclid`, `gclid`, `igshid`, `si`, `utm` | High-intent, true (we literally remove them), low competition — keep + expand |
| **Productivity wedge** ⭐ | `clean markdown link`, `copy clean link`, `share clean link`, `markdown bookmark`, `obsidian link`, `notion link` | The audience Clean Links ignores — our differentiator as search terms |
| Action/intent | `remove tracking from link`, `strip tracking parameters`, `clean url`, `tidy link`, `untrack link` | Core demand |
| Privacy | `link privacy`, `private link`, `no tracking`, `share private` | Trust wedge |
| Category/competitor | `url cleaner`, `link cleaner`, `clean links`, `tracking remover` | Capture comparison intent (also an ASA play, §4) |

Rules: no spaces in `keywords.txt` (wasted budget); don't repeat name/subtitle words (Apple stems plurals); rotate in seasonal/wedge terms each refresh. **Run the [`app-store-optimization`](#) skill** for live volume/difficulty/competitor-gap data and the [`asc-metadata`](#) skill to ship changes.

### 1.2 Conversion levers (the App Store *page*, not just ranking)
- **Screenshots are the #1 conversion driver.** Current 3 (Home hero / History / Parameters) are good; make shot 1 a **benefit-captioned "wow"** (the before→after dirty-link transform) and add a **Markdown/format** shot (the PKM wedge) and an **AI-advisor** shot ("your phone spots trackers we don't even have a rule for"). Caption-led, not raw UI.
- **Custom Product Pages (CPPs):** build audience-specific pages — a *PKM/Markdown* CPP, a *privacy* CPP — and point §3/§4/§7 traffic at the matching one. Lets you A/B messaging without touching the default listing.
- **Product Page Optimization (PPO):** A/B-test subtitle, icon, and shot order natively. First test: subtitle "Remove trackers from links" vs a productivity-led variant ("Clean links for your notes").
- **In-App Events + promotional text** (editable without a build) for timely hooks: new-feature beats, "now catches N more trackers" catalog updates (markets itself, roadmap §3).
- **Ratings/reviews engine:** the in-app review gate already fires after real exports. **Volume is a beatable moat** — Clean Links has only ~49 ratings; a focused push to a few hundred genuine reviews materially lifts conversion *and* LLMO (§3).

### 1.3 Localization = ASO multiplier (roadmap §7)
Each locale is a **new keyword field + storefront + screenshot set** at near-zero product risk. Order: **🇯🇵 ja** (home market, founder-QA'd) → **🇩🇪 de** (most privacy-sensitive storefront — the positioning translates literally) → 🇫🇷🇪🇸. The identifier-key catalog is already built for it.

### 1.4 Measure (kpis): ASC App Analytics — impressions → product-page views → **conversion rate** → installs, by keyword/source/storefront; TelemetryDeck for what happens after (activation §3, north star §0).

---

## 2. SEO — an owned web home that compounds

The *app* can't rank on the open web; a **content site can** — and it's the home base for SEO, LLMO (§3), paid destinations (§4), and the landing page (§5). **Decision: buy `linkclean.app`** (open in [growth-roadmap.md](../product/growth-roadmap.md) §10 / TODO) and ship a site — recommend yes; it's the connective tissue for every channel below.

### 2.1 Content engine — answer what the buyer searches
The high-intent searches are *educational* ("what is this tracker / how do I remove it"). Map content 1:1 to the keyword clusters:

- **Per-tracker glossary (programmatic SEO):** one page per major parameter — *"What is `utm_source`? (and how to remove it)"*, `fbclid`, `gclid`, `igshid`, `si`, … Each: what it is, who adds it, why it's a privacy leak, how to strip it (→ LinkClean). Dozens of pages, all matching the literal-tracker keywords, all LLMO-citable (§3).
- **How-to guides:** *"How to remove tracking from a link on iPhone"*, *"Clean Amazon / YouTube / Instagram / Reddit share links"*, *"Get a clean Markdown link for Obsidian/Notion."* These are the long-tail the PKM/researcher audience actually types.
- **Comparison pages:** *"LinkClean vs Clean Links"* (honest — lead with our wedges: formats, AI advisor, history, design, audited; concede their breadth) to capture competitor-intent search. (Clean Links already runs `/compare/*` pages — match the play.)
- **The pitch + legal home:** features, pricing, privacy policy (move off the generic `ken0nek.com` subdomain), support.

### 2.2 Technical SEO
Fast static site (Astro/Next static); `SoftwareApplication` + `FAQPage` structured data; Open-Graph/Twitter cards (also feed social + LLM previews, §3); Apple **Smart App Banner**; clean sitemap; privacy-respecting analytics (Plausible/self-host — brand-consistent, no Google Analytics).

---

## 3. LLMO — get recommended by the AI assistants

People increasingly ask ChatGPT / Claude / Perplexity / Gemini *"best privacy URL cleaner for iPhone"* or *"how do I remove UTM tracking from a link."* **Being the recommended answer is the new SEO** — and it's an open field (no competitor owns it yet).

**How models choose what to recommend:** their training corpus + live retrieval. To win both:

- **Be clearly, factually described where models read.** Owned site (§2) with crisp, quotable summaries: *"LinkClean is a privacy-first iOS app that removes tracking parameters (utm_source, fbclid, gclid, …) entirely on-device, exports clean Markdown links, and is a one-time $4.99 purchase — no subscription, no account, no data collection."* Models love clean factual feature lists, FAQ schema, and comparison tables.
- **Seed the corpora LLMs retrieve from:** Reddit (r/privacy, r/iosapps, r/ObsidianMD, r/shortcuts, r/apple), Hacker News, Product Hunt, GitHub, and *listicles* ("best URL cleaner apps 2026," "Obsidian link tools"). Genuine presence in these = citations.
- **Answer the question on owned pages** so the model can lift the answer *with our name in it*: the glossary + how-to pages (§2) are dual-purpose SEO/LLMO assets.
- **Auditable/open catalog as a trust + citation asset** (§6, §10): an open, documented rule list is exactly the kind of verifiable source models prefer to cite over a competitor's un-audited "71+ services" marketing claim.

**Measure (hard):** no clean attribution — proxy via **branded-search lift** in ASC (LLM recommendations drive people to search "LinkClean"), referral traffic from `chat.openai.com`/`perplexity.ai`/etc. in site analytics, and periodic manual prompt-audits ("ask 5 assistants the buyer's question — are we named?").

---

## 4. Paid ads — a measured accelerant, brand-consistent

**Not the engine.** For a bootstrapped privacy app with ~$4.99 one-time LTV, paid is for *validating* and *accelerating* proven funnels, not for buying growth. The brand also rules out the highest-ROAS-but-invasive tactics (Meta pixel retargeting contradicts "no tracking").

- **Apple Search Ads (ASA) — the only clean fit.** On-platform, Apple-privacy-respecting, high-intent, measurable to install.
  - **Brand defense first** (bid on `linkclean`, `link clean`): pennies, captures competitor poaching and LLM/word-of-mouth-driven branded searches before a competitor does.
  - **Top-intent generics + literals** (your §1 clusters; tracker terms), and **competitor terms** (`clean links`, `url cleaner`) — capture comparison shoppers, land them on the *comparison* CPP (§1.2).
  - Start tiny ($5–20/day), optimize on **cost-per-Pro-conversion** (kpis §15), not installs. Point each ad group at its matching **CPP**.
- **Meta / Google: skip until scale.** Pixel/retargeting is brand-toxic and expensive vs a $4.99 LTV; only revisit with contextual-only, brand-safe creative once ASA proves CPA < LTV.
- **Budget tiers:** **$0** (organic only, default until launch settles) → **~$150–300/mo** ASA brand + top-intent test → **scale** only where CPA < realized LTV (kpis §17).

---

## 5. Landing page + the "columns"

The LP is the **conversion hub** for every channel: SEO/LLMO home, paid destination, social-share target, App Store funnel, social proof, and legal/support home. Brand: privacy-teal + Liquid Glass, fast, mobile-first.

### 5.1 Page structure (top → bottom)
1. **Hero** — name + one-line value prop + **App Store badge** + a striking product visual; the *wow demo* = an animated **before→after** of a dirty link snapping clean (the single most persuasive asset).
2. **Social proof bar** — rating, "N trackers removed by LinkClean users" (the V3 stat, §6), any press.
3. **Benefit columns** (the "columns" — a 3×2 grid, §5.2).
4. **Comparison table** — LinkClean vs Clean Links vs "doing nothing" (§5.3).
5. **How it works** — 3 steps: *Share/paste → Clean (see what's removed) → Copy / Markdown / export.*
6. **Privacy section** — the trust columns: *on-device · no account · nothing leaves your phone · auditable.*
7. **Pricing** — Free vs **Pro, one-time $4.99** ("pay once, yours forever — never a subscription").
8. **FAQ** (with `FAQPage` schema — doubles as SEO/LLMO, §3).
9. **Repeat CTA** — App Store badge.

### 5.2 The benefit columns (concrete — reuse the App Store description sections)

| Column | Header | One-liner |
|---|---|---|
| 1 | **Clean as you share** | Strip trackers right in the Share Sheet — one tap, never leave the app you're in. |
| 2 | **See what you remove** | A calm proof-of-work: every tracker removed, every leftover, fully transparent. |
| 3 | **Private by design** | 100% on-device. No account, no servers — your links never leave your phone. |
| 4 | **Built for your notes** ⭐ | Copy a clean `[title](url)` Markdown link, ready for Obsidian, Notion, anywhere. |
| 5 | **Searchable history** ⭐ | Every cleaned link, searchable — copy, re-clean, or reopen any time. |
| 6 | **Smart, on-device** ⭐ | Apple-Intelligence advisor flags trackers we don't even have a rule for — privately. |

Columns 4–6 (⭐) are the wedge the comparison drives home; they're what a free funnel competitor won't build.

### 5.3 Comparison columns (honest)

| | **LinkClean** | Clean Links | Do nothing |
|---|---|---|---|
| Removes trackers | ✅ | ✅ | ❌ |
| **Markdown / format export** | ✅ | ❌ | ❌ |
| **Searchable history** | ✅ | ✗ (no history) | ❌ |
| **On-device AI advisor** | ✅ | ❌ | ❌ |
| Auditable rule list | ✅ (planned, §6) | ✗ un-audited | — |
| On-device / no account | ✅ | ✅ | — |
| Price | $4.99 once | Free* | Free |

*Concede honestly: Clean Links is free + broader (QR, Send-to-Mac, web/PWA). Win the rows that matter to *people who work with links*, not the breadth race.

### 5.4 Tech
Static + structured data (§2.2); OG image = the before→after hero (drives social/LLM previews); Smart App Banner; deep-links to the App Store with ASA/CPP UTM-free tracking (eat your own dog food — clean links only).

---

## 6. "Wow" features as growth assets

Reframe: a wow feature isn't just product — it's a **distribution mechanism** (word-of-mouth, screenshots, press, LLM citations). Prioritize features that are *demoable, shareable, and differentiating.*

| Feature | Status | Growth role |
|---|---|---|
| **V3 shareable privacy card** ⭐⭐ | planned (roadmap §5) | **The viral loop.** "I removed 1,247 trackers" rendered as a post — on-brand growth *instead of* appending "cleaned with LinkClean" to URLs. Single highest-leverage organic feature — **prioritize it.** |
| **On-device AI advisor (ai-A)** ⭐⭐ | shipped | The **press + LLMO + "AI-without-the-gimmick"** hook: "your iPhone privately spots trackers we don't even have a rule for." Pitch to Apple-press (they cover on-device-AI). |
| **Redirect transparency** | shipped | The "see where a link *really* goes" demo — screenshot-friendly, trust-building. |
| **Markdown / Copy-as-HTML / Title+URL formats** ⭐ | Markdown shipped; formats planned | The **PKM word-of-mouth engine** (kpis §11 = growth engine): the feature note-takers tell other note-takers about. |
| **Liquid Glass design** | shipped | The App Store-screenshot and "this is beautiful" review driver. |
| **Auditable / open catalog** | candidate (§10) | Trust + LLMO citation asset; differentiates vs un-audited competitor claims. |

**Principle:** ship wow features that (a) differentiate vs Clean Links, (b) demo in one screenshot/GIF, (c) reinforce the productivity+privacy wedge. The **V3 share card + the AI angle + format export** are the three that most directly drive §3/§5/§7.

---

## 7. Community & content — the connective tissue

The differentiated audience clusters in findable communities — show up value-first, never spammy:

- **Where they are:** r/ObsidianMD, r/Notion, r/PKMS, r/shortcuts, r/privacy, r/apple, r/iosapps; Hacker News; Product Hunt; Obsidian/Notion forums + Discords; Mastodon/Bluesky privacy + Apple-dev circles; indie-iOS newsletters/podcasts.
- **Launch beats:** **Product Hunt** launch, **"Show HN,"** a value-first post in 2–3 relevant subreddits (a *how-to* that happens to use LinkClean, not an ad), and **Apple-press pitches** (MacStories, 9to5Mac, AppStories — they *already covered Clean Links*, so the category has their attention).
- **Ongoing engine:** the SEO glossary/how-tos (§2) → LLMO (§3); the V3 share card (§6) → organic loops; **Shortcuts Gallery** submission (App Intents already shipped, S1); build-in-public from the founder. Each feeds branded search (→ ASO §1) and reviews.

---

## 8. Localization as a growth multiplier
Covered in §1.3 — it's both an **ASO** lever (new keyword fields/storefronts) and a **market-expansion** lever (roadmap §7). 🇩🇪 de is the standout: the most privacy-sensitive major storefront, where the positioning needs no translation of *intent*.

---

## 9. Sequencing & measurement

**Don't boil the ocean — phase it:**

| Phase | Focus | Concrete |
|---|---|---|
| **Now (at launch)** | Nail the free, compounding basics | ASO metadata + screenshots + first CPP (§1); buy `linkclean.app` + ship the LP (§5); launch beats — PH / Show HN / subreddits / press (§7); reviews engine running |
| **Next (0–3 mo)** | Build the compounding content + the viral loop | SEO glossary + how-to + comparison pages (§2) → LLMO seeding (§3); ship **V3 share card** (§6); start **ASA brand + top-intent** small (§4); 🇯🇵 ja localization (§1.3) |
| **Then (3–6 mo)** | Scale only what's proven | scale ASA where **CPA < LTV** (kpis §15/§17); 🇩🇪 de; format-export wow (§6); evaluate open catalog (§10) |

**Measurement map** — plug into [kpis.md](kpis.md), don't reinvent:
- **Acquisition:** ASC App Analytics — impressions → page views → **conversion rate** → installs, sliced by source/keyword/storefront (kpis §1); ASA dashboard (CPA).
- **Activation & value:** TelemetryDeck — install → first export (kpis §3), the **north-star** exports/active-user/week (§0), surface mix (§6).
- **Revenue:** ASC — install → Pro conversion (kpis §15), net rev / 10K downloads (§17).
- **Web/LLMO:** Plausible (referrals incl. AI tools), branded-search lift in ASC, periodic prompt-audits (§3).
- **Honest constraint:** the privacy brand + Apple's privacy mean **attribution is coarse** — lean on ASC source breakdowns, branded-search lift, and launch-beat holdout reasoning, not pixel-perfect last-click.

---

## 10. Open decisions (ratify before executing)

1. **Buy `linkclean.app`?** — **Recommend yes.** It's the home for SEO/LLMO/LP/paid and the App Store marketing URL. Low cost, unblocks §2/§3/§5. (Carried from [growth-roadmap.md](../product/growth-roadmap.md) §10 / TODO.)
2. **Paid budget tier?** — $0 / ~$150–300-mo ASA test / scale (§4). Default $0 until launch + ASO settle; ASA brand-defense is the first dollar worth spending.
3. **A free web cleaner on the site?** — Clean Links Web is a top-of-funnel magnet for them. A *deliberately limited* web cleaner (cleans one link, no history/formats) would be a strong SEO/LLMO entry point that upsells the app — but it gives away the core free and competes with our own listing. **Lean: yes, limited + app-upsell**, decide with the LP.
4. **Open-source / publish the catalog?** — Trust + LLMO citation asset and a real differentiator vs un-audited competitor claims; cost is maintenance + exposing the rule set. **Lean: publish a read-only, documented catalog page** (not necessarily the whole engine).
5. **Add QR?** — Clean Links' QR-safety angle has real search demand and it's a parity gap; but it's scope creep off the link-productivity wedge. **Defer** unless ASO/LLMO data shows QR-intent driving meaningful comparison loss.
