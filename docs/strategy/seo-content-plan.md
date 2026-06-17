# LinkClean — SEO Content Plan

> **Status: in-progress — 2026-06-16 (last sync).** Originally proposed 2026-06-13. The execution-level content + information-architecture plan behind the SEO/LLMO pillar of [growth-marketing.md](growth-marketing.md) §2–§3. *What pages to build, in what structure, targeting which searches, and in what order.*
> **Scope:** the owned content site at **`linkclean.app`** (domain decision in growth-marketing §10) — its architecture, repeatable content templates, the full content map, internal-linking/funnel design, schema, and a build order. Not the App Store listing (that's ASO, growth-marketing §1) or the LP design (growth-marketing §5).
> **Builds on:** [growth-marketing.md](growth-marketing.md) (§2 SEO, §3 LLMO), [competitor-clean-links.md](competitor-clean-links.md) (Clean Links already runs guide + compare pages — match and out-depth them), the literal-tracker keywords already in [app-store-metadata.md](../../apps/ios/LinkClean/docs/release/app-store-metadata.md).
> **Accuracy note:** content briefs below give a one-line best-understanding of each parameter; **anything tagged ⚠️verify must be fact-checked (and ideally cited) before publishing** — a privacy authority that gets a parameter wrong loses the trust that is the whole point. Run the `deep-research` skill per uncertain piece.

---

## Status snapshot (2026-06-16)

✅ marks rows shipped on `linkclean.app` (Phase 3b — public production). Items without ✅ remain forward-looking. Some rows below were **added during execution** and weren't in the 2026-06-13 plan; those are flagged inline with *(added Wave 1.5)* or *(added beyond plan)*. The doc keeps its forward-looking shape — this block is just the sync line.

**Shipped (en only — ja + de still Phase 3c):**
- ✅ Home / LP (with Hallmark Manifesto redesign on 2026-06-16)
- ✅ `/trackers/` hub + **36 spokes** (the plan listed ~25; Wave 1.5 added the email family, the modern Google Ads params, the regional/functional kind, and a fuller utm family)
- ✅ `/guides/` hub + **4 guides** (`remove-utm-parameters`, `clean-youtube-link`, `clean-amazon-link`, `clean-x-twitter-link`)
- ✅ `/learn/` hub + **4 pillars** (`do-cleaned-links-still-work`, `whats-hidden-in-a-share-link`, `x-twitter-share-url-explained`, `click-ids-vs-utm-tags`)
- ✅ Phase 3b deploy (domain + DNS + `deploy:prod`) — see [monorepo-and-landing.md](monorepo-and-landing.md) §6 for the as-executed runbook

**Still outstanding (in roughly Wave-2 / Wave-3 order):**
- The platform "clean a ___ link" guides for Instagram / TikTok / Spotify / LinkedIn / Reddit / Google Maps; the **Markdown / Obsidian / Notion** guide (the PKM wedge)
- The privacy how-tos under `/guides/*` (Private Relay, disable ATT, Safari checklist, Stop link tracking iPhone)
- The `/learn/*` pillars left: tracking-parameter, link-decoration, redirect/shortener, tracking-vs-functional
- The `/url/` URL-anatomy hub + trivia link-magnets
- The `/compare/*` commercial pages (Best URL cleaner / vs Clean Links / online-vs-app)
- `/clean` free web cleaner (open decision; §9 #1)

**Decided closed (not outstanding):** the `/privacy-policy` · `/terms` · `/support` migration is **off the table** — legal pages stay permanently on `ken0nek.com` (per [monorepo-and-landing.md](monorepo-and-landing.md) §8). Both 1.0.0 and 1.1.0 (live as of 2026-06-16) point at `ken0nek.com/apps/linkclean/{privacy-policy,terms-of-use}/`; migrating would force an iOS resubmission to repoint a URL whose contents don't change.

**Added beyond the original plan (now first-class):**
- `nature: "tracker" | "functional"` on `TrackerSpoke` — functional spokes (e.g. `hl`, `gl`, `t`, `v`, `q`, `lang`) render "LinkClean preserves this — no change" instead of dirty→clean. New `regional` kind + "Region & language (preserved)" hub category. *Honest position: the page explains the parameter and tells the reader LinkClean leaves it alone, which is a trust play.*
- `kind: "email"` (Email marketing) as a first-class trackers-hub category, alongside `utm`/`ads`/`regional`
- `SearchDemand` (`high | medium | low`) per spoke — ranks the glossary list and weights internal-link density
- Inline-markdown converter (`src/markdown.ts`) — `**bold**` + backtick `code` rendered across every prose surface (TL;DR, paragraphs, bullets, FAQ, step bodies)
- Optional `table` field on `LearnSection` — used by the X deep dive's 9-row `s=` reference table (rendered as `.ref-table`)
- Site-wide header nav (Glossary / Guides / Learn) — wasn't called out in §2's IA tree but added when the second + third hubs landed
- `pnpm verify-links` (`scripts/verify-links.ts`) — graph-walks the rendered route map for dead internal links; runs as a CI gate
- Hallmark Manifesto macrostructure on the home page (2026-06-16) — replaces the original Long Document layout

---

## 1. SEO thesis

The **app** can't rank on the open web; an **authority content site can**, and it compounds for free. The buyer's searches are *informational with buying-adjacent intent* — *"what is fbclid,"* *"how to remove tracking from a YouTube link,"* *"is it safe to share links with utm."* Each page **answers the question, names the underlying privacy problem, and presents LinkClean as the one-tap fix** → App Store.

Three jobs, one page set:
1. **SEO** — rank for hundreds of long-tail tracker/URL/privacy queries (low competition, high intent).
2. **LLMO** (growth-marketing §3) — these clean, factual, schema-marked pages are exactly what ChatGPT/Perplexity/Claude cite when asked the buyer's question.
3. **Funnel** — every page routes to the App Store with a contextual CTA; the highest-intent pages ("how to clean an X link") convert hardest.

**Authority model: hub-and-spoke (topic clusters).** A few **hub** pages (glossaries, pillar guides) link down to many **spoke** pages (individual explainers/how-tos), which link back up and across. Google rewards the dense internal topical graph; it also gives LLMs a coherent corpus to retrieve.

---

## 2. Information architecture

```
linkclean.app/
├─ /                          Home / landing page  (growth-marketing §5)
├─ /clean                     Free limited web cleaner  (tool page; open decision, growth-marketing §10) ── top-of-funnel magnet
├─ /trackers/                 HUB: Tracking-parameter glossary (A–Z)
│   ├─ /trackers/utm-source        spoke: "What is utm_source?"
│   ├─ /trackers/fbclid            spoke …
│   ├─ /trackers/gclid             spoke …
│   └─ … (one per parameter)
├─ /guides/                   HUB: How-to guides
│   ├─ /guides/clean-youtube-link
│   ├─ /guides/remove-utm-parameters
│   ├─ /guides/private-relay-safari
│   └─ …
├─ /learn/                    HUB: Concepts (what is a tracking parameter, click ID, link decoration…)
├─ /url/                      HUB: URL anatomy & trivia
├─ /compare/                  Comparison / commercial (vs Clean Links, best url cleaners)
├─ /privacy-policy, /terms, /support     (move off the generic ken0nek subdomain)
```

Every spoke carries the same skeleton (§3), links **up** to its hub + **across** to 2–3 sibling spokes + **out** to the App Store. Hubs are living indexes that grow as spokes ship.

---

## 3. Content templates (so 50 pages stay consistent + schema-clean)

**A. Tracker explainer** — `/trackers/<param>` — the workhorse, one per parameter.
> **H1:** "What is `<param>`? (and how to remove it)"
> 1. **TL;DR** — one bolded sentence answering it (the featured-snippet + LLM-citation target).
> 2. **What it is / who adds it** — origin (e.g. platform, analytics vendor).
> 3. **What it reveals about you** — the privacy stake (the hook).
> 4. **Example** — a real dirty URL → the clean version (visual, copy-pasteable).
> 5. **How to remove it** — manual (delete from `?…`) *and* "LinkClean removes `<param>` automatically, in your Share Sheet."
> 6. **Is it safe to remove?** — functional vs tracking nuance (builds trust; ties to the catalog design).
> 7. **FAQ** (2–3 Q's) + **CTA** (App Store badge).
> Schema: `Article` + `FAQPage` (+ `DefinedTerm` linked to the glossary set).

**B. How-to / "clean a `<platform>` link"** — `/guides/clean-<platform>-link`.
> **H1:** "How to remove tracking from a `<platform>` link" → numbered steps (`HowTo` schema) → "the one-tap way" (LinkClean Share Sheet / Shortcut) → before/after → FAQ → CTA.

**C. Privacy how-to** — `/guides/<task>` (Private Relay, disable ATT…).
> Same as B but the task is an iOS privacy setting; CTA frames LinkClean as the *link-level* complement to the OS-level setting.

**D. Glossary hub** — `/trackers`, `/url`.
> A–Z `DefinedTermSet`; each entry = a one-line definition linking to its spoke; intro paragraph + the LinkClean CTA. The flagship link-magnet.

**E. Concept / pillar** — `/learn/<concept>`.
> Longer-form authority piece (what is link tracking, click IDs, link decoration) that links *down* to many spokes — the topical-authority anchor.

**Enhancements added during Wave 1 / Wave 1.5 (not in the 2026-06-13 templates):**
- **Template A variant — functional spoke.** When `nature: "functional"` is set on a `TrackerSpoke` (`hl`, `gl`, `t`, `v`, `q`, `lang`), the renderer swaps the dirty→clean comparison for an "Example URL → LinkClean preserves this, no change" panel. Schema stays `Article` + `FAQPage` but the hook flips from *"safe to remove"* to *"safe to keep — here's why."*
- **Template E variant — embedded reference table.** A `table` field on `LearnSection` renders as a `.ref-table`. First use: the 9-row `s=` reference in `/learn/x-twitter-share-url-explained/` (sourced from the Unfurl open-source URL parser).
- **Inline markdown across prose surfaces.** Authored ``**bold**`` and `` `code` `` are converted via `src/markdown.ts` after HTML-escape; applies to TL;DR, paragraphs, bullets, FAQ answers, and step bodies — TL;DR base weight is bumped to 600 so emphasised `**text**` stays visually distinct.
- **Hub category labels.** `trackers/chrome.ts` maps kind → human label: `utm` → "UTM tags", `ads` → "Ad click IDs", `email` → "Email marketing", `regional` → "Region & language (preserved)". Categories drive both the hub index and the per-category JSON-LD scoping.

---

## 4. The content map

Tiers: **T1** = build first (highest intent × volume × funnel, or a cornerstone hub) · **T2** = the compounding long tail · **T3** = link-bait / trivia / commercial.

### 4.0 Top of funnel — the pages everything links to
| Page | Target query | Tier | Note |
|---|---|---|---|
| ✅ **Home / LP** | brand + "url cleaner iphone" | T1 | App intro, the benefit columns + comparison table, App Store link (growth-marketing §5). Visual redesign 2026-06-16: Hallmark Manifesto macrostructure replaced the original Long Document. |
| **Free web cleaner** `/clean` | "url cleaner online", "remove utm from url" | T1\* | \*Open decision (growth-marketing §10): a *deliberately limited* cleaner (one link, no history/formats) that upsells the app — Clean Links Web is exactly this magnet |
| ✅ **What's hidden in a share link?** (flagship) | "what is hidden in a link", "what do shared links track" | T1 | Shipped at `/learn/whats-hidden-in-a-share-link/`. Cornerstone privacy-awareness piece; links to the whole `/trackers` hub. |

### 4.1 Tracker explainers — `/trackers/*` (template A) — the keyword core
| Page | Target query | Tier | One-liner (⚠️ = verify before publish) |
|---|---|---|---|
| **What does UTM stand for?** | "what does utm stand for", "what is utm" | T1 | **Urchin Tracking Module** — from Urchin, the analytics co. Google bought (→ Google Analytics). Strong trivia + authority hook. The Urchin origin currently rides inside the `utm_source` spoke's vendor block; consider promoting to a standalone page. |
| ✅ What is `utm_source` / `utm_medium` / `utm_campaign`? | "what is utm_source" etc. | T1 | Shipped as three separate spokes. UTM family — campaign attribution. Matches the literal keywords. |
| ✅ What is `utm_term` / `utm_content` / `utm_id`? *(added beyond plan)* | "what is utm_term" etc. | T2 | The full UTM family — `_term` (paid-search keyword), `_content` (creative variant), `_id` (GA4 campaign id). Long-tail completeness; ships UTM coverage end-to-end. |
| ✅ What is `fbclid`? | "what is fbclid", "remove fbclid" | T1 | **Facebook Click Identifier** — ties a click back to a Meta ad/profile. |
| ✅ What is `gclid`? (+ `dclid`, `gbraid`, `wbraid`) | "what is gclid" | T1 | **Google Click Identifier** (+ the privacy-era variants). All four shipped as separate spokes. |
| ✅ What is `msclkid`? *(added Wave 1.5)* | "what is msclkid", "bing click id" | T2 | **Microsoft Click ID** — Bing/Microsoft Advertising. Wasn't enumerated in the original plan but is the canonical "Google has gclid, Microsoft has ___" answer. |
| ✅ What is `gad_source` / `gad_campaignid`? *(added beyond plan)* | "what is gad_source" | T3 | The modern Google Ads URL params (post-2023). Tail completeness; surfaces in real-world dirty URLs alongside `gclid`. |
| ✅ What is `srsltid`? | "what is srsltid", "remove google shopping tracking" | T3 | Google Shopping result-source token. Promoted from plan §4.1's tail entry to a full spoke. |
| What is `igshid`? | "what is igshid", "instagram link tracking" | T1 | **Instagram Share ID** — added when you share from IG. *Not yet shipped — Wave 2 alongside the Instagram clean-link guide.* |
| What is `si` in YouTube / Spotify links? | "what is si in youtube link", "spotify si parameter" | T1 | **Share identifier** added by the Share button (per-share attribution token). *Clarify the common confusion: `si` is YouTube/Spotify, not X.* *Not yet shipped — Wave 2.* |
| What is `s` and `t` in X / Twitter links? | "what is s in twitter link", "twitter t parameter" | T1 | `s` = source/surface code; `t` = a share-tracking token (~2022+). **Shipped as a `/learn/` deep dive** rather than a tracker spoke — see §4.4's `x-twitter-share-url-explained`. The 9-row `s=` reference table is the LLM-citable artifact. |
| What is `rsc` / `_rsc` in a LinkedIn link? | "what is rsc in url", "rsc parameter linkedin" | T2 | ⚠️verify — `_rsc` is most likely **Next.js React Server Components** routing/cache (a *technical* artifact, not user tracking); LinkedIn's actual trackers are `rcm`/`trackingId`/`lipi`/`midToken`. **Great angle: "is `rsc` tracking you, or just a tech param?"** — positions LinkClean as the nuanced authority. *Still queued for Wave 3 after verification.* |
| ✅ Per-vendor click IDs: `ttclid` (TikTok), `twclid` (X Ads), `yclid` (Yandex), `epik` (Pinterest), `li_fat_id` (LinkedIn Ads), `sc_click_id` (Snapchat) | "what is ttclid" etc. | T2 | All six shipped as separate spokes. Long-tail, low competition. *`igshid` still pending — Wave 2.* |
| ✅ Marketplace ad params: `spm` (Alibaba), `rdt_cid` (Reddit) *(added beyond plan)* | "what is spm parameter", "what is rdt_cid" | T2 | Asian-marketplace + Reddit-ads coverage. Shipped to broaden the catalog past the Western analytics big-four. |
| ✅ Email-newsletter trackers: `mc_eid` / `mc_cid` / `mc_tc` (Mailchimp), `mkt_tok` (Marketo), `_hsenc` / `_hsmi` (HubSpot), `_kx` (Klaviyo) | "what is mc_eid" etc. | T2 | Seven email-marketing spokes shipped under the new `email` kind / "Email marketing" hub category (added Wave 1.5). `_kx` and `mc_tc` were not in the plan's draft list. `vero_id` and `oly_enc_id` are still pending. |
| What is `ref` / `ref_src` / `ref_url`? | "what is ref in url" | T2 | Referrer params — nuance: sometimes functional. *Not yet shipped.* |
| What is `cmpid` / `icid` (generic campaign IDs)? | long-tail | T3 | Tail completeness; matches catalog/reference entries. *Not yet shipped.* |

### 4.1b Functional / preserved-parameter explainers — `/trackers/*` (template A variant, `nature: "functional"`) — *added Wave 1.5*

Not in the original plan. Wave 1.5 introduced the `nature: "tracker" | "functional"` distinction so we can publish authoritative pages for the URL parameters readers *think* are trackers but aren't — a nuance-as-trust play. The renderer swaps the dirty→clean comparison for "Example URL → LinkClean preserves this, no change." Listed under the "Region & language (preserved)" hub category.

| Page | Target query | Tier | One-liner |
|---|---|---|---|
| ✅ What is `hl` in Google / YouTube URLs? | "what is hl in url", "youtube hl parameter" | T2 | **Host language** — Google's UI-language hint (`hl=ja` = Japanese UI). Functional. Was the trigger for the entire `nature: "functional"` template. |
| ✅ What is `gl` in Google URLs? | "what is gl in google url" | T3 | **Geographic location** — country hint for Google Search/Maps/Shopping. Functional. |
| ✅ What is `t` in a YouTube link? *(timestamp, not tracking)* | "what is t in youtube link", "youtube timestamp parameter" | T2 | YouTube video timestamp — `?t=42s`. The honest "no, this is just a timestamp" piece — disambiguates from X's `t=` (a true tracking token). |
| ✅ What is `v` in a YouTube link? | "what does v= mean in youtube" | T3 | YouTube video identifier — the actual content key, not tracking. |
| ✅ What is `q` in a URL? *(search query)* | "what is q parameter in url", "what does q= mean" | T2 | The de-facto search-query parameter (Google, Wikipedia, GitHub, …). Functional. Surfaces in nearly every dirty URL — readers need to know LinkClean keeps it. |
| ✅ What is `lang` in a URL? | "what is lang parameter in url" | T3 | Generic language-selection convention. Functional. |

### 4.2 Platform "clean a link" how-tos — `/guides/*` (template B) — action intent, high conversion
| Page | Target query | Tier | Status |
|---|---|---|---|
| ✅ How to remove **UTM** parameters from a URL | "how to remove utm parameters", "strip utm from link" | T1 | `/guides/remove-utm-parameters/` |
| ✅ How to clean a **YouTube** share link | "remove si from youtube link", "clean youtube link" | T1 | `/guides/clean-youtube-link/` |
| ✅ How to get a clean **Amazon** product link | "clean amazon link", "remove amazon ref tag" | T1 | `/guides/clean-amazon-link/` |
| ✅ How to clean an **X / Twitter** link | "remove tracking twitter link" | T1 | `/guides/clean-x-twitter-link/` |
| How to clean an **Instagram** link | "remove igshid", "clean instagram link" | T1 | *Wave 2 — pairs with the `igshid` spoke.* |
| How to clean a **TikTok** / **Spotify** / **LinkedIn** / **Reddit** / **Google Maps** link | per-platform | T2 | *Wave 2 — TikTok/Reddit can lean on the shipped `ttclid`/`rdt_cid` spokes; LinkedIn pairs with the `rsc` verification.* |
| How to get a clean **Markdown** link for **Obsidian / Notion** | "obsidian clean link", "markdown link without tracking" | T1 | ⭐ the PKM wedge — still the highest-leverage unshipped guide. |

### 4.3 Glossaries & URL trivia — hubs + link-bait (templates D/E)
| Page | Target query | Tier | Status |
|---|---|---|---|
| ✅ **Tracking-parameter glossary (A–Z)** `/trackers/` | "tracking parameters list", "url tracking parameters" | T1 (hub) | Lists 36 spokes, grouped by `kind` → "UTM tags" / "Ad click IDs" / "Email marketing" / "Region & language (preserved)". Includes the `DefinedTermSet` schema. |
| **Anatomy of a URL** (scheme/host/path/query/fragment) `/url/anatomy` | "parts of a url", "url anatomy", "what is a query string" | T2 (hub) | *Not yet shipped — `/url/` hub still empty.* |
| **URL trivia**: what `?` `&` `#` `%20` mean; why links have `#`; the longest URLs | "what does %20 mean", "what is the # in a url" | T3 | *Not yet shipped — Wave 3 link-bait.* |
| **"The 100 most common tracking parameters"** (data/reference) | "list of tracking parameters" | T3 | *Partially superseded* — the shipped `/trackers/` hub already runs 36 fully-written spokes (richer than the planned "100 entries one-liner list"); a separate "raw catalog dump" page is still optional Wave 3 link-magnet bait. |

**Hubs added during execution that weren't enumerated in §2's IA tree** (silently shipped alongside §4.2/§4.4):
- ✅ **`/guides/` hub** — `CollectionPage` schema listing every guide; breadcrumb back-link on every spoke
- ✅ **`/learn/` hub** — same pattern for the pillar pages
- ✅ **Site-wide header nav** — Glossary / Guides / Learn (added once the second + third hubs landed)

### 4.4 Concept / pillar pages — `/learn/*` (template E) — authority + LLMO
| Page | Target query | Tier | Status |
|---|---|---|---|
| What is a **tracking parameter**? | "what is a tracking parameter" | T1 (pillar) | *Not yet shipped — Wave 2 priority; still the canonical pillar entry point.* |
| ✅ **Click IDs vs UTM tags** (the fbclid/gclid family vs the utm family) | "what is a click id", "click id vs utm" | T2 | `/learn/click-ids-vs-utm-tags/` — pillar reframed: not "what is a click ID?" alone but the comparison vs UTM, which captures both queries and gives the reader a mental model. |
| What is **link decoration** / **bounce tracking**? | "what is link decoration", "bounce tracking" | T2 | The concept Apple/browsers fight — ties to the brand. *Not yet shipped.* |
| ✅ **Do cleaned links still work?** | "is it safe to remove tracking from links" | T1 | `/learn/do-cleaned-links-still-work/` — answers the #1 user worry → trust + conversion. |
| ✅ **What's hidden in a share link?** (flagship privacy-awareness piece — also listed in §4.0) | "what is hidden in a link", "what do shared links track" | T1 | `/learn/whats-hidden-in-a-share-link/`. |
| ✅ **What `t=` and `s=` mean in an X (Twitter) share URL** *(added Wave 1.5)* | "what is s in twitter link", "twitter t parameter" | T1 | `/learn/x-twitter-share-url-explained/` — the X-codes deep dive promised in §4.1 and §9 #4. Anatomy + a 9-row `s=` reference table (sourced from the Unfurl open-source URL parser). First use of the `SectionTable` template feature. |
| Tracking vs **functional** parameters (what's safe to strip) | "which url parameters are safe to remove" | T2 | Ties to the catalog design / advisor. *The functional template (4.1b) ships this idea per-parameter; a unified pillar is still due.* |
| What is a **redirect / link shortener**, and is it tracking you? | "do link shorteners track you" | T2 | Ties to E1 redirect unwrapping. *Not yet shipped.* |

### 4.5 Privacy how-tos — `/guides/*` (template C) — adjacent top-of-funnel (your asks + more)
| Page | Target query | Tier |
|---|---|---|
| How to enable **iCloud Private Relay** on Safari | "enable private relay", "private relay safari" | T1 | Settings → Apple Account → iCloud → Private Relay (needs iCloud+). |
| How to **disable App Tracking Transparency** ("Allow Apps to Request to Track") | "turn off app tracking iphone", "disable att" | T1 | Settings → Privacy & Security → Tracking → off. |
| **Safari privacy settings checklist** (Hide IP, Prevent Cross-Site Tracking, Private Relay, Hide Email) | "safari privacy settings" | T2 | bundles several into one authority page |
| How to **stop link tracking on iPhone** (umbrella) | "stop link tracking iphone" | T1 | links to the whole site; names LinkClean as the link-level layer |
| How to set up a **Shortcut to clean links** | "shortcut to remove tracking", "clean url shortcut" | T2 | drives the Shortcuts Gallery (S1 already shipped) |
| How to clean links from the **Share Sheet** | "share sheet url cleaner" | T2 | doubles as support/onboarding content |

### 4.6 Commercial / comparison — `/compare/*` — bottom of funnel
| Page | Target query | Tier |
|---|---|---|
| **Best URL cleaner apps for iPhone (2026)** | "best url cleaner app", "best link cleaner ios" | T1 | own the category listicle (be honest; LinkClean leads on the wedges) |
| **LinkClean vs Clean Links** | "linkclean vs clean links", "clean links alternative" | T2 | capture competitor intent; lead with formats/AI/history/audited, concede breadth |
| Free online URL cleaner vs app vs manual | "free url cleaner" | T2 | routes to `/clean` + the app |

---

## 5. Internal linking & the funnel to the app

- **Every spoke** links: **up** to its hub, **across** to 2–3 siblings ("see also: `gclid`, `igshid`"), and **out** via a contextual in-content CTA — *"LinkClean strips `fbclid` automatically, right in your Share Sheet → [App Store]."* The CTA is **specific to the page's parameter/task**, not generic.
- **Hubs** index their spokes and carry the primary App Store CTA + the App Store **Smart App Banner** (iOS Safari).
- **Pillars (`/learn`)** link *down* into many spokes → concentrate topical authority.
- **The `/clean` web tool** (if built) is the conversion pivot: it cleans one link, *shows* what it removed, then says "want this in your Share Sheet, with Markdown + history? → LinkClean."
- **Eat the dog food:** every outbound/share link on the site is itself clean (no UTM) — a credibility detail, and a quiet demo.

---

## 6. Technical SEO & schema (per template)

- **Schema:** `SoftwareApplication` (home/`/clean`), `Article`+`FAQPage` (trackers/learn), `HowTo` (guides), `DefinedTermSet`/`DefinedTerm` (glossaries), `BreadcrumbList` (everywhere). FAQ + HowTo schema win rich results *and* are LLM-friendly.
- **Each page:** a one-sentence bolded TL;DR near the top (snippet + LLM citation target), descriptive title/meta, OG image (the before→after visual — drives social + AI-preview cards), clean slug.
- **Site:** Cloudflare Workers + Hono (`hono/jsx`, server-rendered per page/locale at worker boot — static-fast, zero client JS, no build step beyond `wrangler`), XML sitemap, `robots.txt` (AI-bot allowlist), `llms.txt`, canonical + hreflang tags, Smart App Banner, privacy-respecting analytics (TelemetryDeck Web — mirrors the iOS app's analytics, no GA, no Plausible). Full stack + rationale: [monorepo-and-landing.md](monorepo-and-landing.md) §2.
- **LLMO crossover (growth-marketing §3):** the same TL;DR + FAQ + comparison-table structure is what assistants lift; seed the pages into Reddit/HN/PH answers so they enter the retrieval corpus.

---

## 7. Build order & production

**Don't write 50 pages at once — ship the cornerstones, then the long tail compounds.**

| Wave | Build | Why | Status |
|---|---|---|---|
| **Wave 1 (cornerstones)** | Home/LP · `/trackers` hub · "What's hidden in a share link?" · UTM + `fbclid` + `gclid` explainers · "How to remove UTM parameters" · "How to clean a YouTube link" · "Do cleaned links still work?" | Highest intent/volume + the hub that makes everything else discoverable | ✅ **Shipped** (Phase 3a → Phase 3b deploy). |
| ✅ **Wave 1.5 (enrichment — not in original plan)** | +5 tracker spokes (`utm_medium`, `utm_campaign`, `msclkid`, `ttclid`, `mc_eid`) · +1 functional spoke (`hl`) introducing the `nature: "tracker" \| "functional"` distinction + new `regional` kind + "Email marketing" hub category · +2 guides (`clean-amazon-link`, `clean-x-twitter-link`) · +1 learn pillar (`click-ids-vs-utm-tags`) · the X (Twitter) deep dive at `/learn/x-twitter-share-url-explained/` (anatomy + 9-row `s=` reference table) · `/guides/` + `/learn/` hubs · site-wide header nav · inline-markdown converter (`src/markdown.ts`) | Filled the catalog up to credible authority depth before pushing breadth; the functional/preserved-parameter category turned a blind spot into a trust play; the X deep dive captured the bare-keyword queries (`s in twitter link`) without spawning a per-code spoke. | ✅ **Shipped** (between Phase 3a and Phase 3b; sites are live on `linkclean.app`). |
| **Wave 2 (wedge + breadth)** | The Markdown/Obsidian guide · `si`/`igshid` explainers · Instagram/TikTok/Spotify/LinkedIn/Reddit/Google-Maps clean-how-tos · Private Relay + disable-ATT guides · `/learn/tracking-parameter` pillar · `vero_id` / `oly_enc_id` email spokes · `ref` / `ref_src` / `ref_url` | The PKM wedge + the platforms with the most search demand + the privacy top-of-funnel | Queued — `s=` + `t=` already covered by the Wave-1.5 deep dive; `X/Amazon` guides already shipped, so Wave 2's platform list shrinks accordingly. |
| **Wave 3 (long tail + link-bait)** | The remaining per-vendor param spokes (`cmpid` / `icid` / generic) · URL-anatomy + trivia under `/url/` · the comparison/listicle pages under `/compare/` · `rsc` (⚠️post-verify) · `/clean` free web cleaner (if open-decision §9 #1 lands "yes") | Compounds; low competition; the link-magnets. **Legal pages stay on `ken0nek.com` permanently** — see status snapshot above. | Queued. |

**Production model:** founder-drafted + AI-assisted from the §3 templates (consistent, fast); **`deep-research` skill to verify any ⚠️ parameter before publishing**; the `copywriting` skill for the LP/`/clean` conversion copy. Cadence: a small steady drip (e.g. 2–4 pages/week) beats a one-time dump — fresh, growing clusters signal authority.

---

## 8. Measurement (plugs into [growth-marketing.md](growth-marketing.md) §9)

- **Rankings & traffic:** Search Console (impressions, position, CTR by query/page), Plausible (organic sessions, top pages, AI-tool referrers).
- **Funnel:** organic → App Store outbound clicks (the proxy for assisted installs, since attribution is coarse), `/clean` tool → app CTA rate.
- **LLMO:** branded-search lift in ASC + periodic prompt-audits ("do 5 assistants name LinkClean for the buyer's question?").
- **Leading signal:** number of indexed pages ranking in the top 10 for their target query — the compounding curve to watch.

---

## 9. Open decisions
1. **`/clean` free web cleaner?** — strong SEO/LLMO magnet + conversion pivot, but gives the core away free (mirrors Clean Links Web). **Lean: yes, deliberately limited + app-upsell.** (Carried from growth-marketing §10.) ❓ **Still open.**
2. ✅ **Publish the catalog as `/trackers` data?** — **Decided: yes.** The shipped `/trackers/` hub is a read-only, auditable view of 36 catalog entries; the per-spoke `DefinedTerm` schema makes the whole hub LLM-citable.
3. ✅ **Programmatic vs hand-written tracker pages?** — **Decided: template-driven, each individually written.** Every shipped spoke carries hand-written copy for the privacy stake + dirty/clean example; the template (template A and the 4.1b functional variant) only enforces structure. No thin auto-pages.
4. ✅ **`rsc` and the X `s`-codes** — *Partially decided.* The X `s=`/`t=` codes shipped as a `/learn/` deep dive after verification against the Unfurl open-source URL parser (template E + new `SectionTable` field). `rsc` is **still queued for Wave 3 post-verification** — the "is `rsc` actually tracking you, or just a tech artifact?" angle is the strongest unshipped Wave-3 piece.
