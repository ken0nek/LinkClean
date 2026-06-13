# LinkClean — SEO Content Plan

> **Status: proposed — 2026-06-13.** The execution-level content + information-architecture plan behind the SEO/LLMO pillar of [growth-marketing.md](growth-marketing.md) §2–§3. *What pages to build, in what structure, targeting which searches, and in what order.*
> **Scope:** the owned content site at **`linkclean.app`** (domain decision in growth-marketing §10) — its architecture, repeatable content templates, the full content map, internal-linking/funnel design, schema, and a build order. Not the App Store listing (that's ASO, growth-marketing §1) or the LP design (growth-marketing §5).
> **Builds on:** [growth-marketing.md](growth-marketing.md) (§2 SEO, §3 LLMO), [competitor-clean-links.md](competitor-clean-links.md) (Clean Links already runs guide + compare pages — match and out-depth them), the literal-tracker keywords already in [app-store-metadata.md](../release/app-store-metadata.md).
> **Accuracy note:** content briefs below give a one-line best-understanding of each parameter; **anything tagged ⚠️verify must be fact-checked (and ideally cited) before publishing** — a privacy authority that gets a parameter wrong loses the trust that is the whole point. Run the `deep-research` skill per uncertain piece.

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

---

## 4. The content map

Tiers: **T1** = build first (highest intent × volume × funnel, or a cornerstone hub) · **T2** = the compounding long tail · **T3** = link-bait / trivia / commercial.

### 4.0 Top of funnel — the pages everything links to
| Page | Target query | Tier | Note |
|---|---|---|---|
| **Home / LP** | brand + "url cleaner iphone" | T1 | App intro, the benefit columns + comparison table, App Store link (growth-marketing §5) |
| **Free web cleaner** `/clean` | "url cleaner online", "remove utm from url" | T1\* | \*Open decision (growth-marketing §10): a *deliberately limited* cleaner (one link, no history/formats) that upsells the app — Clean Links Web is exactly this magnet |
| **What's hidden in a share link?** (flagship) | "what is hidden in a link", "what do shared links track" | T1 | The cornerstone privacy-awareness piece; links to the whole `/trackers` hub; the most shareable + LLM-citable page |

### 4.1 Tracker explainers — `/trackers/*` (template A) — the keyword core
| Page | Target query | Tier | One-liner (⚠️ = verify before publish) |
|---|---|---|---|
| **What does UTM stand for?** | "what does utm stand for", "what is utm" | T1 | **Urchin Tracking Module** — from Urchin, the analytics co. Google bought (→ Google Analytics). Strong trivia + authority hook. |
| What is `utm_source` / `utm_medium` / `utm_campaign`? | "what is utm_source" etc. | T1 | The UTM family — campaign attribution; one page each or a family page + anchors. Matches the literal keywords. |
| What is `fbclid`? | "what is fbclid", "remove fbclid" | T1 | **Facebook Click Identifier** — ties a click back to a Meta ad/profile. |
| What is `gclid`? (+ `dclid`,`gbraid`,`wbraid`) | "what is gclid" | T1 | **Google Click Identifier** (+ the privacy-era variants). |
| What is `igshid`? | "what is igshid", "instagram link tracking" | T1 | **Instagram Share ID** — added when you share from IG. |
| What is `si` in YouTube / Spotify links? | "what is si in youtube link", "spotify si parameter" | T1 | **Share identifier** added by the Share button (per-share attribution token). *Clarify the common confusion: `si` is YouTube/Spotify, not X.* |
| What is `s` and `t` in X / Twitter links? | "what is s in twitter link", "twitter t parameter" | T1 | `s` = source/surface code (which client the share came from); `t` = a share-tracking token (~2022+). ⚠️verify exact `s` codes are undocumented — explain the *concept*, don't invent code meanings. |
| What is `rsc` / `_rsc` in a LinkedIn link? | "what is rsc in url", "rsc parameter linkedin" | T2 | ⚠️verify — `_rsc` is most likely **Next.js React Server Components** routing/cache (a *technical* artifact, not user tracking); LinkedIn's actual trackers are `rcm`/`trackingId`/`lipi`/`midToken`. **Great angle: "is `rsc` tracking you, or just a tech param?"** — positions LinkClean as the nuanced authority. |
| What is `igsh` / `igshid`, `ttclid` (TikTok), `twclid`, `li_fat_id` (LinkedIn ads), `yclid` (Yandex), `epik` (Pinterest) | "what is ttclid" etc. | T2 | Per-vendor click IDs — long-tail, low competition; one spoke each. |
| What is `mc_eid` / `mc_cid` (Mailchimp), `mkt_tok` (Marketo), `_hsenc`/`_hsmi` (HubSpot), `vero_id`, `oly_enc_id` | "what is mc_eid" etc. | T2 | Email-newsletter trackers — searched by privacy-aware readers *and* marketers. |
| What is `ref` / `ref_src` / `ref_url`? | "what is ref in url" | T2 | Referrer params — nuance: sometimes functional. |
| What is `srsltid` (Google Shopping), `cmpid`/`icid` (generic campaign IDs) | long-tail | T3 | Tail completeness; matches catalog/reference entries. |

### 4.2 Platform "clean a link" how-tos — `/guides/*` (template B) — action intent, high conversion
| Page | Target query | Tier |
|---|---|---|
| How to remove **UTM** parameters from a URL | "how to remove utm parameters", "strip utm from link" | T1 |
| How to clean a **YouTube** share link | "remove si from youtube link", "clean youtube link" | T1 |
| How to get a clean **Amazon** product link | "clean amazon link", "remove amazon ref tag" | T1 |
| How to clean an **X / Twitter** link | "remove tracking twitter link" | T1 |
| How to clean an **Instagram** link | "remove igshid", "clean instagram link" | T1 |
| How to clean a **TikTok** / **Spotify** / **LinkedIn** / **Reddit** / **Google Maps** link | per-platform | T2 |
| How to get a clean **Markdown** link for **Obsidian / Notion** | "obsidian clean link", "markdown link without tracking" | T1 | ⭐ the PKM wedge — the audience Clean Links ignores |

### 4.3 Glossaries & URL trivia — hubs + link-bait (templates D/E)
| Page | Target query | Tier |
|---|---|---|
| **Tracking-parameter glossary (A–Z)** `/trackers` | "tracking parameters list", "url tracking parameters" | T1 (hub) |
| **Anatomy of a URL** (scheme/host/path/query/fragment) `/url/anatomy` | "parts of a url", "url anatomy", "what is a query string" | T2 (hub) |
| **URL trivia**: what `?` `&` `#` `%20` mean; why links have `#`; the longest URLs | "what does %20 mean", "what is the # in a url" | T3 | shareable, LLM-citable |
| **"The 100 most common tracking parameters"** (data/reference) | "list of tracking parameters" | T3 | link-magnet; mirrors the app's catalog (auditable-catalog asset, growth-marketing §10) |

### 4.4 Concept / pillar pages — `/learn/*` (template E) — authority + LLMO
| Page | Target query | Tier |
|---|---|---|
| What is a **tracking parameter**? | "what is a tracking parameter" | T1 (pillar) |
| What is a **click ID**? (the fbclid/gclid family) | "what is a click id" | T2 |
| What is **link decoration** / **bounce tracking**? | "what is link decoration", "bounce tracking" | T2 | the concept Apple/browsers fight — ties to the brand |
| **Do cleaned links still work?** | "is it safe to remove tracking from links" | T1 | answers the #1 user worry → trust + conversion |
| Tracking vs **functional** parameters (what's safe to strip) | "which url parameters are safe to remove" | T2 | ties to the catalog design / advisor |
| What is a **redirect / link shortener**, and is it tracking you? | "do link shorteners track you" | T2 | ties to E1 redirect unwrapping |

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
- **Site:** fast static (Astro/Next-static), XML sitemap, `robots.txt`, canonical tags, Smart App Banner, privacy-respecting analytics (Plausible — brand-consistent, no GA).
- **LLMO crossover (growth-marketing §3):** the same TL;DR + FAQ + comparison-table structure is what assistants lift; seed the pages into Reddit/HN/PH answers so they enter the retrieval corpus.

---

## 7. Build order & production

**Don't write 50 pages at once — ship the cornerstones, then the long tail compounds.**

| Wave | Build | Why |
|---|---|---|
| **Wave 1 (cornerstones)** | Home/LP · `/trackers` hub · "What's hidden in a share link?" · UTM + `fbclid` + `gclid` explainers · "How to remove UTM parameters" · "How to clean a YouTube link" · "Do cleaned links still work?" | Highest intent/volume + the hub that makes everything else discoverable |
| **Wave 2 (wedge + breadth)** | The Markdown/Obsidian guide · `si`/`s`+`t`/`igshid` explainers · Amazon/X/Instagram clean-how-tos · Private Relay + disable-ATT guides · `/learn/tracking-parameter` pillar | The PKM wedge + the platforms with the most search demand + the privacy top-of-funnel |
| **Wave 3 (long tail + link-bait)** | the remaining per-vendor param spokes · URL-anatomy + trivia · "100 tracking parameters" reference · the comparison/listicle pages · `rsc` (⚠️post-verify) | Compounds; low competition; the link-magnets |

**Production model:** founder-drafted + AI-assisted from the §3 templates (consistent, fast); **`deep-research` skill to verify any ⚠️ parameter before publishing**; the `copywriting` skill for the LP/`/clean` conversion copy. Cadence: a small steady drip (e.g. 2–4 pages/week) beats a one-time dump — fresh, growing clusters signal authority.

---

## 8. Measurement (plugs into [growth-marketing.md](growth-marketing.md) §9)

- **Rankings & traffic:** Search Console (impressions, position, CTR by query/page), Plausible (organic sessions, top pages, AI-tool referrers).
- **Funnel:** organic → App Store outbound clicks (the proxy for assisted installs, since attribution is coarse), `/clean` tool → app CTA rate.
- **LLMO:** branded-search lift in ASC + periodic prompt-audits ("do 5 assistants name LinkClean for the buyer's question?").
- **Leading signal:** number of indexed pages ranking in the top 10 for their target query — the compounding curve to watch.

---

## 9. Open decisions
1. **`/clean` free web cleaner?** — strong SEO/LLMO magnet + conversion pivot, but gives the core away free (mirrors Clean Links Web). **Lean: yes, deliberately limited + app-upsell.** (Carried from growth-marketing §10.)
2. **Publish the catalog as `/trackers` data?** — the glossary *is* a read-only, auditable view of the catalog — a trust + LLMO asset vs the competitor's un-audited "71+ services." **Lean: yes** (growth-marketing §10).
3. **Programmatic vs hand-written tracker pages?** — templates make near-programmatic generation feasible, but thin auto-pages get penalized. **Lean: template-driven but each genuinely written** (the privacy stake + example make each non-thin).
4. **`rsc` and the X `s`-codes** — ship only after verification; if `rsc` turns out to be a pure Next.js artifact, the *honest* "it's not actually tracking you" piece is *more* valuable than a wrong "it's a tracker" one.
