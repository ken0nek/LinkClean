# LinkClean — Monorepo & Landing-Page Build Plan

> **Status: proposed — 2026-06-13; revised 2026-06-16** (descoped Phase 1 to local-only; resequenced after 1.0.0 launch + 1.1.0 submission; folded the `apps/ios/LinkClean/` container, docs subdir split, and `.gitignore` split into the structure). The **engineering** plan to (a) restructure this repository into a monorepo that absorbs the iOS app and (b) scaffold, deploy, and ship the landing page at **`linkclean.app`**. The infrastructure counterpart to [seo-content-plan.md](seo-content-plan.md) (*what pages to build*) and [growth-marketing.md](growth-marketing.md) §2 / §5 (*why an owned web home, and what the LP must say*). *This doc covers repo structure, the web stack, the migration mechanics, CI, domain/DNS, and sequencing — not content, copy, or SEO (those are the two docs above).*
> **Builds on:** [growth-marketing.md](growth-marketing.md) §2 + §5, [seo-content-plan.md](seo-content-plan.md) §2/§6, [competitor-clean-links.md](competitor-clean-links.md).
> **Reference implementation:** **`../whyzard/apps/landing/`** — the founder's existing, deployed Cloudflare landing site. **We mirror its stack and conventions** (Hono/JSX on Cloudflare Workers, Wrangler, TelemetryDeck Web, the per-locale + content-cluster structure). Per [CLAUDE.md](../../CLAUDE.md) "find the closest existing example and match its pattern" — that example is Whyzard. **This supersedes the abstract "Astro/Next-static" lean in seo-content-plan §6** (which should be updated to match).
> **⚠️ Hard constraint (updated 2026-06-16):** iOS **1.0.0 is LIVE on the App Store** (since 2026-06-15) — **constraint cleared.** A new constraint takes its place: **1.1.0 was just submitted (2026-06-16) and is awaiting review**, so the same "don't break fastlane mid-review in case we need to ship a fix build" logic now applies to 1.1.0. **⇒ Phase 2 (iOS absorb) waits until 1.1.0 clears review.** Phase 1 (local monorepo scaffold) and **Phase 3a (local landing build — no Cloudflare, no domain)** are both unblocked **right now**; **Phase 3b (public deploy)** is independently unblocked from iOS but gated on the decision to commit to the domain + Cloudflare account.

---

## 0. Goal & the one decision that drives everything

Priority #3, verbatim: *"Buy linkclean.app, ship the LP + the first SEO/LLMO cornerstone pages. Outside the iOS codebase, compounds for free, the home base for every other channel."*

So **the landing page is the value; the monorepo is the vehicle.** Three separable pieces with very different risk profiles, so we do them in order:

| Work | Value | Risk / effort | Blocks on |
|---|---|---|---|
| Scaffold `apps/landing/` locally (Phase 1) | Foundation for #3 — gets the monorepo shape right | Low (greenfield, mirrors a working repo, nothing existing touched, no Cloudflare account / no domain) | nothing |
| Move the iOS app into `apps/ios/LinkClean/` (Phase 2) | Tidiness + the monorepo end-state | **Real** — Xcode refs, the `LinkCleanKit` SPM relative path, fastlane, scripts, screenshot pipeline, and a release in flight | **iOS 1.1.0 clearing review** (1.0.0 already live) |
| Build Wave-1 content locally (Phase 3a) | Most of #3's value, no external dependencies | Low (local-only — content + JSON-LD + sitemap, runs under `wrangler dev`) | nothing |
| Public launch — domain + Cloudflare deploy (Phase 3b) | Makes the work visible | Domain purchase + DNS + the Cloudflare AI-bots zone trap (§6) | nothing iOS-related (App Store listing is live to point at) |
| Content cadence + ja/de locales (Phase 3c) | Compounds | Steady drip; ja/de drop in via the existing locale loop | Phase 3b live |

**Therefore: do not big-bang.** Phase 1 is **local-only** — stand up the monorepo skeleton + scaffold the landing app so it runs under `wrangler dev`, *while the iOS app stays exactly where it is at the repo root.* Phase 2 absorbs the iOS app once **1.1.0** clears review. Phase 3 now splits into **3a (local content build), 3b (public launch — domain + deploy), and 3c (content cadence + locales)**, so the high-value content work is unblocked *right now* without buying a domain or touching Cloudflare. 3b is the gate to "publicly visible"; 3a accumulates everything that gets shipped the moment that gate flips. Identical end state; sequencing decouples the content build from the infra commitment.

**Why a monorepo at all:** one home for the app + the web property that markets it; shared `docs/` and brand assets; atomic cross-cutting changes (a tracker added to the catalog *and* its `/trackers/<param>` page in one PR); a single base every channel points back to. **The cost** is the one-time iOS-absorb repath (§4) — paid once, deferred safely.

---

## 1. Target layout

Mirrors `../whyzard/` (a pnpm workspace whose JS apps live under `apps/`). LinkClean adds the iOS app as a sibling app, "slid" into a named project container (`apps/ios/LinkClean/`) so fastlane stays beside `LinkClean.xcodeproj` — the Fastfile's `XCODEPROJ = "LinkClean.xcodeproj"` resolves CWD-relative, so the xcodeproj and `fastlane/` MUST remain siblings:

```
linkclean/                                ← repo root
├─ apps/
│  ├─ ios/
│  │  ├─ .gitignore                       ← iOS-only patterns, split out of root in Phase 2 (xcuserdata, .ipa, .dSYM, .build/, fastlane outputs)
│  │  └─ LinkClean/                       ← the entire current iOS app, "slid" here in one Phase-2 commit
│  │     ├─ LinkClean/ · LinkClean.xcodeproj · LinkCleanKit/ (SPM — MUST stay sibling to .xcodeproj)
│  │     ├─ LinkCleanAction/ · LinkCleanMarkdownAction/ · LinkCleanWidget/ · *Tests/ · *.entitlements
│  │     ├─ fastlane/ · Gemfile · Gemfile.lock · mise.toml · scripts/ · Screenshots/
│  │     ├─ docs/                         ← iOS-only operational docs that moved from root: iap/, release/, dashboards/
│  │     └─ ARCHITECTURE.md · AGENTS.md · CHANGELOG.md · CLAUDE.md · README.md   (iOS-specific, moved here)
│  └─ landing/                            ← NEW — Hono on Cloudflare Workers (Phase 1), mirrors whyzard/apps/landing
│     ├─ wrangler.jsonc                        # worker name, assets dir, dev/prod envs, custom-domain routes
│     ├─ package.json                          # "@linkclean/landing"; scripts: dev / deploy:dev / deploy:prod
│     ├─ tsconfig.json                         # extends ../../tsconfig.base.json; jsxImportSource: hono/jsx
│     ├─ biome.json                            # parity with whyzard (formatter + linter)
│     ├─ src/
│     │  ├─ index.tsx                          # route registration; pre-renders each page/locale at worker boot
│     │  ├─ page.tsx                           # Page component + inlined OKLCH CSS + JSON-LD builder
│     │  ├─ brand.ts                           # brand constants (URLs, author, App Store link, LAST_UPDATED)
│     │  ├─ copy/                              # per-locale typed Copy modules (en first; ja/de later)
│     │  ├─ i18n/locales.ts                    # locale registry + path/url helpers
│     │  └─ trackers/                          # the /trackers glossary cluster ── twins whyzard's src/qa/
│     │     ├─ data.ts                         #   the authored parameter catalog (one entry per tracker)
│     │     ├─ select.ts                       #   hub/spoke resolution (a category hub at N+ spokes)
│     │     └─ paths.ts · chrome.ts            #   path helpers + per-page chrome strings
│     ├─ public/                               # robots.txt (AI allowlist), llms.txt, og/, app-store badge, icon
│     └─ CLAUDE.md                             # web conventions for agents working here
├─ docs/                                  ← stays at root; slimmed by Phase 2 to cross-cutting only: strategy/, product/, plans/ (← root plans/ merges here), raw/, archive/, ROADMAP.md. iap/, release/, dashboards/ move into apps/ios/LinkClean/docs/.
├─ .xcodebuildmcp/config.yaml             ← stays at root (Xcode sim default config, read from cwd by the MCP)
├─ .github/workflows/                     ← stays at root (path-scoped in §5)
├─ pnpm-workspace.yaml                    ← NEW (root) — registers apps/landing; mirrors whyzard
├─ package.json                           ← NEW (root) — workspace root
├─ tsconfig.base.json                     ← NEW (root) — shared TS base that apps/landing extends
├─ biome.json                             ← NEW (root) — parity with whyzard (formatter + linter for JS/TS)
├─ README.md                              ← rewritten as a monorepo overview (Phase 2, not Phase 1)
├─ CLAUDE.md                              ← monorepo-wide conventions (iOS specifics move to apps/ios/LinkClean/CLAUDE.md, Phase 2)
├─ .gitignore                             ← non-iOS half only after the Phase 2 split (skills allowlist, global macOS, Phase-1 web patterns)
└─ .mcp.json · .claude/ · .agents/ · skills-lock.json
```

**What moves vs what stays:**

| Moves into `apps/ios/LinkClean/` (Phase 2) | Stays at repo root |
|---|---|
| `LinkClean/`, `LinkClean.xcodeproj`, `LinkCleanKit/`, the three extensions, both test targets, `*.entitlements` | `.git/`, `.github/`, `.mcp.json`, `.claude/`, `.agents/`, `skills-lock.json`, `.xcodebuildmcp/` |
| `fastlane/`, `Gemfile`, `Gemfile.lock`, `mise.toml`, `scripts/`, `Screenshots/` | `docs/strategy/`, `docs/product/`, `docs/plans/` (now includes the merged-in root `plans/`), `docs/raw/`, `docs/archive/`, `docs/ROADMAP.md` (cross-cutting / design-level) |
| `ARCHITECTURE.md`, `AGENTS.md`, `CHANGELOG.md`, and the iOS halves of `README.md` / `CLAUDE.md` (split, §4) | the new monorepo-root `README.md` + `CLAUDE.md`; the new root `pnpm-workspace.yaml` / `package.json` / `tsconfig.base.json` / `biome.json` |
| `docs/iap/`, `docs/release/`, `docs/dashboards/` (pure iOS operations) → `apps/ios/LinkClean/docs/{iap,release,dashboards}/` | (root `plans/` is **dissolved**, not preserved — its contents merge into `docs/plans/`) |
| **iOS half of root `.gitignore`** (xcuserdata, .ipa/.dSYM*, .build/, all six `fastlane/*` patterns) → `apps/ios/.gitignore`, **one level higher than `LinkClean/`** so it scopes the whole iOS workspace | the non-iOS half of `.gitignore` (global macOS, skills allowlist, Phase-1 web patterns) |

> Build artifacts (`*.ipa`, `*.dSYM.zip`, `.build/`) are already git-ignored and untouched. **Phase 1** adds `node_modules/`, `dist/`, `.wrangler/` (un-anchored — matches any depth, so today's iOS-at-root and tomorrow's `apps/*/` both work) to the root `.gitignore`. **Phase 2** splits out the iOS half into `apps/ios/.gitignore` (§4 step 6); root keeps the global macOS block, the skills allowlist (`/.agents/skills/...`, `/.claude/skills/...`), and the Phase-1 web patterns.
>
> **On the pnpm workspace:** LinkClean has only one JS package today (`apps/landing`), so the root workspace files are mostly for **parity with whyzard** — same `pnpm --filter @linkclean/landing` ergonomics, same `tsconfig.base.json` + `biome.json`, room for a future shared package. The Xcode app stays outside the JS workspace entirely (polyglot repo; nothing to orchestrate between Swift and Node).

---

## 2. Landing-page stack — mirror `whyzard/apps/landing`

Same stack, top to bottom. Where Whyzard solved a problem, inherit the solution rather than rediscover it.

| Layer | Choice (= whyzard) | Notes for LinkClean |
|---|---|---|
| **Runtime/host** | **Cloudflare Workers**, driven by **Wrangler** | `wrangler.jsonc`: `main: src/index.tsx`, `compatibility_flags: ["nodejs_compat"]`, `assets.directory: "./public"`, named `development` / `production` envs. Worker names `linkclean-landing-dev` / `linkclean-landing`. |
| **Framework** | **Hono** + `hono/jsx` (server-rendered) | Pages pre-rendered **per page/locale at worker boot**; **no client JS, no build step** beyond wrangler's bundling. CSS inlined in one `<style>` in `page.tsx` via `hono/html`'s `raw()`. |
| **Language** | **TypeScript**, `jsxImportSource: "hono/jsx"`, extends root `tsconfig.base.json` | — |
| **Content cluster** | `src/trackers/` — **twins whyzard's `src/qa/`** | `data.ts` = authored parameter catalog; `select.ts` = hub-at-N resolution; the `/trackers` hub + `/trackers/<param>/` spokes (seo-content-plan §2–§3) pre-render at boot exactly like whyzard's `/questions/` index → hubs → question pages. `index.tsx` also emits `/sitemap.xml` + `/healthz`. |
| **Analytics** | **TelemetryDeck Web** (a *separate* `linkclean-landing` TD app) | ⭐ Better fit than the Plausible I first floated — **LinkClean already uses TelemetryDeck for iOS**, so the web→install funnel joins via App Store Connect → Sources + `ct=` campaign tokens, same as whyzard. Reuse whyzard's `TELEMETRY_INIT` verbatim, incl. the **`text/plain` Blob CORS trick** for the `AppStoreTapped` tap signal and the `isTestMode` hostname check. Cookieless → stays on-brand. |
| **SEO/LLMO** | JSON-LD graphs · per-locale hreflang/canonical · `robots.txt` AI-bot allowlist · `llms.txt` | LinkClean graphs per seo-content-plan §6: `SoftwareApplication` (home) + `Article`+`FAQPage` (trackers/learn) + `HowTo` (guides) + `DefinedTermSet` (the glossary). Copy whyzard's `public/robots.txt` AI allowlist (GPTBot, ClaudeBot, PerplexityBot, OAI-SearchBot, Applebot-Extended, …) and its `llms.txt` brand-brief format. |
| **Design** | OKLCH tokens, system fonts, light/dark via `prefers-color-scheme`, **no webfonts** | Swap whyzard's navy/bronze for LinkClean's **privacy-teal** accent. Hero + `og:image` = the **before→after dirty-link transform** (seo-content-plan §6) — the most shareable/LLM-citable visual; source from the iOS app's brand assets. |
| **i18n** | per-locale `Copy` modules + `i18n/locales.ts`; default locale at `/`, others prefixed | **Launch en-only**, but build on whyzard's scaffolding so **ja → de** drop in later as ASO multipliers (growth-marketing §1.3) with no rearchitecting. |

---

## 3. Phased plan

### Phase 1 — Monorepo skeleton + local landing scaffold  *(now; zero iOS risk, **local-only — no Cloudflare account, no domain purchase, no public deploy**)*
**The goal is to prove the monorepo setup works**, not to ship the LP. iOS stays at the repo root untouched; we add `apps/` beside it. Public launch (domain + Cloudflare deploy + Wave-1 content) moves to Phase 3.

1. Add root workspace files (`pnpm-workspace.yaml`, root `package.json`, `tsconfig.base.json`, `biome.json`) — copy whyzard's, retarget to `@linkclean/*`. Extend the root `.gitignore` with the un-anchored web patterns (`node_modules/`, `dist/`, `.wrangler/`). **Leave the iOS-flavored root `README.md` / `CLAUDE.md` / `AGENTS.md` / `CHANGELOG.md` as-is — the split happens in Phase 2 (§4 step 5), keeping Phase 1's "zero iOS risk" guarantee intact.**
2. Scaffold `apps/landing/` from whyzard's `apps/landing/` skeleton: `wrangler.jsonc`, `package.json` (`@linkclean/landing`, `dev`/`deploy:dev`/`deploy:prod` scripts — keep all three for parity, only `dev` is used in Phase 1), `tsconfig.json`, `src/{index,page,brand}.tsx`, `src/copy/en.ts`, `src/i18n/locales.ts`, `public/{robots.txt,llms.txt}`, `biome.json`. Add `apps/landing/CLAUDE.md`.
3. **Minimal placeholder Home page** — one rendered route: LinkClean tagline + App Store badge + a stub `/healthz`. Enough to prove the scaffold renders end-to-end (Hono routing, JSX, public assets, TS build). **Wave-1 cornerstones, JSON-LD, sitemap, hreflang, TelemetryDeck wiring all move to Phase 3** (don't wire what we're not shipping).
4. **Local dev verification:** `pnpm install && pnpm --filter @linkclean/landing dev` serves the placeholder on `localhost:<wrangler-dev-port>`; the iOS workspace still opens and builds in Xcode unchanged. **No `deploy:dev`, no `deploy:prod`, no workers.dev preview** — Cloudflare account stays untouched.
5. **Done when:** monorepo installs and the placeholder LP renders from a fresh clone via `pnpm --filter @linkclean/landing dev`; root `tsc --noEmit` is clean for the landing app; iOS app at repo root still green (untouched, all existing tests/builds pass).

### Phase 2 — Absorb the iOS app into `apps/ios/LinkClean/`  *(after iOS 1.1.0 clears review — 1.0.0 is already live)*
A single isolated PR doing only the move + the `.gitignore` split + the docs split (§4). No feature work mixed in — keep the diff reviewable and the revert trivial. The gating reason is unchanged from the original 1.0-flavored plan: if the in-flight submission (now 1.1.0) gets a rejection that needs a fix-build, fastlane/scripts must be in a known-good state. Phase 1 and Phase 3 are both unblocked **right now**; only Phase 2 waits.

### Phase 3a — Local landing build  *(unblocked now; no Cloudflare account, no domain, runs under `wrangler dev`)*

The goal: have the full Wave-1 cornerstone site rendered locally, JSON-LD valid, sitemap built, analytics wired — so that the moment Phase 3b flips the deploy switch, everything ships at once. Each step is independently mergeable; stop at any boundary and the rest stays optional.

**Skills to enable first** (all four sourced from `../whyzard/skills-lock.json`; add to `skills-lock.json` + the `.gitignore` allowlist, then `npx skills experimental_install`):
- **`hono`** (yusukebe/hono-skill) — framework reference; used during 3a.1.
- **`ai-seo`** (coreyhaines31/marketingskills) — TL;DR/FAQ structuring, llms.txt + robots.txt mechanics; used during 3a.2 and 3a.3.
- **`programmatic-seo`** (coreyhaines31/marketingskills) — template-driven content discipline so spokes don't read thin; used during 3a.2 and Phase 3c.
- **`seo-audit`** (coreyhaines31/marketingskills) — pre-launch audit pass; used at the end of 3a.3.

#### 3a.1 — Structural plumbing  *(no user-visible content yet)*

1. Copy Apple's official badge from `../whyzard/apps/landing/public/app-store-badge-en.svg` to `apps/landing/public/`. Swap the placeholder `cta` text link in `src/page.tsx` for the badge image. Skip the ja/de/etc. badges — they wait for Phase 3c.
2. Port `whyzard/src/qa/{types,data,select,chrome,paths}.ts` to `apps/landing/src/trackers/`, retargeted to the LinkClean parameter shape (`{ param, kind, vendor, oneLineWhat, privacyStake, exampleDirty, exampleClean, faq[] }`). Empty `data.ts` for now — entries come in 3a.2.
3. Extract a `Layout` component from `src/page.tsx` (chrome: `<head>` builder, header, footer) so every template uses the same shell. Mirror whyzard's split between `page.tsx` / `qaLayout.tsx` / `questionPage.tsx`.
4. Add a `routes.ts` registry — `{ path, locale, render }[]` — that `index.tsx` loops over to pre-render at boot. The sitemap builder reads from the same array (single source of truth).
5. Add `/sitemap.xml` built from the registry at worker boot — mirror whyzard's `buildSitemap()`.
6. **Stop gate:** `pnpm --filter @linkclean/landing typecheck` clean; `dev` still serves Home from the new Layout; `/sitemap.xml` returns Home only; `/healthz` ok.

#### 3a.2 — Wave-1 cornerstones  *(one template at a time; each = one PR-sized commit)*

Prove the workhorse template first (tracker spoke), then layer the rest.

1. **`/trackers/utm-source`** — first spoke (template A, seo-content-plan §3). JSON-LD: `Article` + `FAQPage`. ⚠️ Verify the "Urchin Tracking Module" trivia via `deep-research` before publishing.
2. **`/trackers/` hub** — template D. JSON-LD: `DefinedTermSet`. Lists the one spoke we have so far; grows as more land.
3. **Home expansion** — replace placeholder with the real LP (benefit columns, comparison table per growth-marketing §5). JSON-LD: `SoftwareApplication`. Use the `copywriting` skill.
4. **`/trackers/fbclid` + `/trackers/gclid`** — proves the `data.ts` catalog scales to N entries.
5. **`/guides/remove-utm-parameters` + `/guides/clean-youtube-link`** — template B. JSON-LD: `HowTo`.
6. **`/learn/do-cleaned-links-still-work`** — template E pillar; answers the #1 conversion blocker.
7. **`/learn/whats-hidden-in-a-share-link`** — the cornerstone privacy piece; links into the whole hub; the most shareable + LLM-citable page.

#### 3a.3 — SEO/LLMO finishing pass

1. Author `public/llms.txt` for LinkClean — use whyzard's file as **format only** (pitch / key facts / citable claims / links) and rewrite the content via `ai-seo` + `copywriting`.
2. Adapt `public/robots.txt` from whyzard's: keep the AI-bot allowlist verbatim, retarget the `Sitemap:` URL to `https://linkclean.app/sitemap.xml`, swap the brand-comment line.
3. Run the `seo-audit` skill across the local site: JSON-LD validates (schema.org validator), every page has a bolded TL;DR, every spoke links **up** to its hub + **across** to 2 siblings + **out** to the App Store (§5 of seo-content-plan).

#### 3a.4 — Analytics  *(optional; can defer to Phase 3b)*

1. Create a separate `linkclean-landing` TelemetryDeck app in the TD dashboard. Add `TD_APP_ID` to `brand.ts`.
2. Port whyzard's `TELEMETRY_INIT` block in `page.tsx` verbatim, including the **`text/plain` Blob CORS trick** for the `AppStoreTapped` signal and the `isTestMode` hostname check.

**3a done when:** Wave-1 pages render locally from a fresh clone via `pnpm --filter @linkclean/landing dev`; `tsc --noEmit` clean; all JSON-LD validates; `seo-audit` pass clean; the landing build has *no* outstanding content TODOs blocking deploy. Analytics either wired or knowingly deferred.

### Phase 3b — Public launch  *(when ready to ship publicly; iOS App Store listing already live to point at)*

1. **Domain + production deploy** (§6): buy `linkclean.app`, move DNS to Cloudflare, configure the production `wrangler.jsonc` `routes` block (`{ pattern: "linkclean.app", custom_domain: true }` + `www`), then `pnpm --filter @linkclean/landing deploy:prod`. Verify HTTPS + the **Block-AI-Bots-OFF** zone check (Cloudflare Security → Bots — see §6, this is the load-bearing one).
2. Submit sitemap to Search Console.
3. **No legal-pages migration.** Privacy / terms stay on `ken0nek.com` permanently — mirrors `../whyzard/`, keeps `fastlane/metadata` and the in-app links stable, and avoids forcing an iOS resubmission just to repoint a URL. See §6 + §8-8.

### Phase 3c — Content cadence + locale expansion  *(post-launch, compounds)*

1. Content Waves 2–3 (seo-content-plan §7) at a steady 2–4 pages/week — use the `programmatic-seo` skill to keep the spoke fleet template-driven without going thin.
2. Add `ja` → `de` locales (copy modules + the matching App Store badge SVGs already in whyzard's `public/`). Whyzard's locale loop is the working reference.
3. Decide on the `/clean` free web cleaner (seo-content-plan §9 / §8-3 below). Lean: not until there's traffic to convert.

---

## 4. iOS absorb — migration mechanics (the risky part, spelled out)

Run as one PR, **only after 1.1.0 clears review** (1.0.0 is already live; the in-flight constraint has moved to 1.1.0 — §0). Verified facts about the blast radius:

- **`LinkClean.xcodeproj` references the package as `relativePath = LinkCleanKit`** (a sibling). Moving the `.xcodeproj` **and** `LinkCleanKit/` **together** into `apps/ios/` preserves that path — **no pbxproj edit needed** for the package link.
- The **only** non-build-product paths in `project.pbxproj` are `../../Frameworks` *build-setting* values (relative to the build products dir, not the source tree) — unaffected by the folder move.
- **There is no iOS build CI to repath** — `.github/` is only the two Claude automation workflows (§5).

Steps:

1. **`git mv` the §1 "moves" column into `apps/ios/LinkClean/`** in one commit (preserves history). The container's `apps/ios/LinkClean/` is a deliberate "just-slide" wrapper — fastlane lives at `apps/ios/LinkClean/fastlane/`, beside the xcodeproj it drives, not at `apps/ios/fastlane/`. Move `LinkClean.xcodeproj` and `LinkCleanKit/` in the same operation so they stay siblings inside the container — the pbxproj's `relativePath = LinkCleanKit` (line 1234) then keeps resolving with no edit. The `@executable_path/../../Frameworks` runpath entries (lines 936/967/999/1031/1062/1093) are runtime bundle paths, not source-tree paths — unaffected.
2. **Open in Xcode once** to re-resolve the package and fix any stray red refs; confirm all targets + schemes build.
3. **fastlane** moves into `apps/ios/LinkClean/fastlane/` (run `bundle exec fastlane` from `apps/ios/LinkClean/`); `Gemfile`/`Gemfile.lock`/`mise.toml` alongside. The Fastfile's `XCODEPROJ = "LinkClean.xcodeproj"` is CWD-relative — works as-is because fastlane sits beside the xcodeproj. Do a **`deliver --verify_only`-style dry run** anyway — fastlane is the likeliest to hold an implicit path assumption.
4. **`scripts/` + `Screenshots/`:** confirmed self-relative — `scripts/capture-raw-screenshots.sh:24` derives its anchor via `dirname "$0"/..`, `scripts/fetch-history-thumbnails.swift:21` via `#filePath`. Both move cleanly. Cosmetic: rename `REPOSITORY_ROOT` in the bash script (post-move it's the iOS workspace root, not the repo root) and update the `swiftc` usage comment in the Swift script to `apps/ios/LinkClean/scripts/...`.
5. **Docs split.** Root-file split: `ARCHITECTURE.md`/`AGENTS.md`/`CHANGELOG.md` → `apps/ios/LinkClean/`. **`CLAUDE.md`:** current iOS rules → `apps/ios/LinkClean/CLAUDE.md`; a slim **root `CLAUDE.md`** describes the monorepo (Claude Code reads them hierarchically, so iOS rules still apply inside `apps/ios/LinkClean/`, web rules inside `apps/landing/`). **`README.md`:** iOS content → `apps/ios/LinkClean/README.md`; new root README = monorepo overview. **Subdir split inside `docs/`:** `docs/iap/`, `docs/release/`, `docs/dashboards/` → `apps/ios/LinkClean/docs/{iap,release,dashboards}/` (pure iOS operations — ASC setup, App Store metadata + screenshots, TelemetryDeck dashboards). **Dissolve root `plans/` → `docs/plans/`:** `git mv plans/SEED.md plans/README.md plans/001-*.md plans/002-*.md docs/plans/` (history preserved); then `rmdir plans/`. Retarget all inbound references in one sweep:
   - `docs/ROADMAP.md` lines 9–10: `../plans/001-*` → `plans/001-ai-c-smart-titles.md` and `../plans/002-*` → `plans/002-e4-short-link-expansion.md` (sibling within `docs/`).
   - `plans/001-ai-c-smart-titles.md` lines 6, 13, 295 (prose): `plans/README.md` → `docs/plans/README.md`, `plans/SEED.md` → `docs/plans/SEED.md`.
   - `plans/002-e4-short-link-expansion.md` lines 6, 13, 258 (prose): same rewrite.
   - The memory entry `plans-seed-guideline.md` (`/Users/ken0nek/.claude/projects/.../memory/`) says "`plans/SEED.md` is the 8-point LinkClean feature-plan checklist" — update to `docs/plans/SEED.md` so future sessions don't chase a dead path.
   Everything else under `docs/` stays at root: `strategy/`, `product/`, `plans/` (now expanded), `raw/`, `archive/`, `ROADMAP.md`.
6. **`.gitignore` split.** Move the iOS half — `xcuserdata/`, `*.ipa`, `*.dSYM`, `*.dSYM.zip`, `.build/`, and all six `fastlane/...` patterns (`fastlane/README.md`, `fastlane/report.xml`, `fastlane/Preview.html`, `fastlane/screenshots/**/*.png`, `fastlane/test_output`, `fastlane/metadata/review_information/`) — to a new `apps/ios/.gitignore`. Place it at `apps/ios/.gitignore` (one level above `LinkClean/`) so a single iOS gitignore scopes the entire iOS workspace; `fastlane/...` patterns become CWD-relative to `apps/ios/` which still matches `apps/ios/LinkClean/fastlane/...` because each pattern is un-anchored (no leading `/`). **Keep at root**: the global macOS block (`.DS_Store`, `._*`, the AppleDouble/Network-Trash/etc lines), the `Carthage/Build/` line (harmless legacy), the skills allowlist paths (`/.agents/skills/...`, `/.claude/skills/...`), and the Phase-1 web patterns (`node_modules/`, `dist/`, `.wrangler/`).
7. **Verify gates (all green before merge):** kit fast lane (`swift test` in `apps/ios/LinkClean/LinkCleanKit/`), app tests (`xcodebuild test -scheme LinkCleanTests` on an OS-26.5 sim, run from `apps/ios/LinkClean/`), a **Release** build (the `.storekit`-in-bundle exception + signing are fragile), and the fastlane dry run. Also `git ls-files --others --ignored --exclude-standard` from root and from `apps/ios/` to confirm the split `.gitignore` files behave (no double-ignoring, no leakage).

---

## 5. CI & deploy

**Today:** no iOS build pipeline. `.github/` has only `claude.yml` (`@claude` mentions) and `claude-code-review.yml` (auto-review on **every** `pull_request`, no path filter). Neither breaks on the iOS move.

**Add with the monorepo:**
- **Deploy = Wrangler, not a host git-integration.** Like whyzard, deploys are CLI: `pnpm --filter @linkclean/landing deploy:prod` (`wrangler deploy --env production`). Manual is fine to start; optionally add a GitHub Action later that runs `wrangler deploy` on push to `apps/landing/**`.
- **Path-scope the auto-review** (`claude-code-review.yml` `paths:`) so landing PRs aren't reviewed through an iOS lens and vice-versa. Cheap, low priority.
- Optional tiny `apps/landing/**`-scoped "typecheck + build" Action so a broken worker can't merge. Defer until the site has enough pages to warrant it.

---

## 6. Domain, DNS & privacy/legal  *(Phase 3b — not Phase 1 or 3a)*

This whole section is deferred to Phase 3b, when we flip the deploy switch. Phase 1 and Phase 3a both stay local; nothing here runs until then.

**Your plan: buy `linkclean.app` on Squarespace, run DNS on Cloudflare.** Registration stays at Squarespace; only DNS authority moves to Cloudflare (which is all the `custom_domain` routes need). Steps:

1. Buy `linkclean.app` at Squarespace Domains.
2. Cloudflare dashboard → **Add a site** → `linkclean.app` → Free plan → it returns two Cloudflare nameservers.
3. At Squarespace, replace the domain's nameservers with those two. Wait for Cloudflare to mark the zone **Active**.
4. `deploy:prod`: the production `routes` block (`{ pattern: "linkclean.app", custom_domain: true }` + `www`) **auto-provisions the cert + DNS records** — no manual CNAME (exactly whyzard's setup). `.app` is HSTS-preloaded → HTTPS is mandatory and now automatic; **never serve http**.
5. ⚠️ **Cloudflare zone silently overrides `robots.txt`.** In **Security → Bots**, verify **"Block AI Bots" is OFF** and Bot Fight Mode is OFF (or allowlists the AI UAs). The edge enforces these *before* the worker serves `robots.txt` — an open allowlist file is meaningless otherwise, and this whole play depends on AI crawlers reaching the `/trackers` pages (growth-marketing §3 / seo-content-plan §6). *(Whyzard's own CLAUDE.md flags this exact trap.)*
6. *(Optional, later: transfer registration to Cloudflare Registrar for at-cost renewal — Cloudflare requires the zone to live there ~60 days first.)*

**Legal pages — staying on `ken0nek.com` permanently.** The app's privacy URL resolves to `https://ken0nek.com/apps/linkclean/privacy-policy/` and terms to `https://ken0nek.com/apps/linkclean/terms-of-use/`; both shipped with 1.0.0 and re-submitted with 1.1.0. We **don't** migrate these onto `linkclean.app` — mirrors `../whyzard/` (same author, same hosting setup), keeps `fastlane/metadata/en-US/privacy_url.txt` and the in-app links stable, and avoids forcing an iOS resubmission just to repoint a URL whose contents don't change. The landing footer already links the same `ken0nek.com` paths via `apps/landing/src/brand.ts` (`PRIVACY_URL` / `TERMS_URL`). The cost is a minor brand-consistency hit (footer + ASC "Privacy Policy" link goes to `ken0nek.com`), which whyzard has lived with fine since 2025. (See §8-8.)

---

## 7. Definition of done

- **Phase 1 (local-only):** monorepo installs and the placeholder landing page renders from a fresh clone via `pnpm install && pnpm --filter @linkclean/landing dev`; the landing app typechecks (`tsc --noEmit` clean); root workspace + `.gitignore` web patterns + scaffold in place; iOS app at repo root still green (untouched). **No public deploy, no domain.**
- **Phase 2:** iOS lives under `apps/ios/LinkClean/`; `.gitignore` split (iOS half at `apps/ios/.gitignore`, web/global half at root) verified via `git ls-files --others --ignored --exclude-standard`; all verify gates green (kit fast lane, app tests, Release build) + fastlane dry run; history preserved; root README/CLAUDE/AGENTS/CHANGELOG split done; `docs/{iap,release,dashboards}/` moved into `apps/ios/LinkClean/docs/`; root `plans/` dissolved into `docs/plans/` with all inbound references retargeted (`docs/ROADMAP.md`, both 001/002 plan files, the memory entry); the rest of `docs/` stayed at root.
- **Phase 3a (local landing build):** Wave-1 pages render locally from a fresh clone (`pnpm --filter @linkclean/landing dev`); `tsc --noEmit` clean; structural plumbing in place (`Layout`, `src/trackers/`, `routes.ts`, `/sitemap.xml`); all JSON-LD validates; `seo-audit` pass clean; every spoke links up/across/out per §5 of seo-content-plan; `llms.txt` + `robots.txt` retargeted to LinkClean; analytics either wired or knowingly deferred. **No public deploy, no domain.**
- **Phase 3b (public launch):** `linkclean.app` live over HTTPS via the `linkclean-landing` worker; sitemap in Search Console; AI-bots zone check passed; every CTA → App Store; TelemetryDeck Web recording (if not done in 3a.4). Legal pages stay on `ken0nek.com` permanently (§6 / §8-8) — no ASC or in-app URL change needed.
- **Phase 3c (content cadence + locales):** content Wave-2/3 cadence running; `ja` → `de` locales live; `/clean` decision made.

---

## 8. Open decisions

1. **Hosting / stack.** **RESOLVED → Cloudflare Workers + Wrangler + Hono, mirroring `whyzard/apps/landing`.** (Supersedes the Astro/Pages/Plausible I first floated and the "Astro" line in seo-content-plan §6 — flagged there for update.)
2. **Move iOS now vs after 1.1.0 clears review.** **Lean: after 1.1.0 review** — 1.0.0 is already live, but 1.1.0 is mid-review (submitted 2026-06-16); the submission-in-flight constraint (§0) now applies to 1.1.0 and makes deferring near-unarguable. Phase 1 (local scaffold) and Phase 3 (public launch) don't need the move, so neither is blocked by this.
3. **Build the `/clean` free web cleaner in Phase 3c?** Strong SEO/LLMO magnet + conversion pivot, but gives the core away free (seo-content-plan §9-1). **Lean: not in Phase 3a (Wave-1 first), not in Phase 3b (don't gate launch on it).** Add `/clean` as a Hono island during Phase 3c once there's traffic to convert.
4. **pnpm workspace for a single JS package?** Mild overkill today, but it's **parity with whyzard** at trivial cost. **Lean: yes, mirror it.** (Keep `apps/landing` self-contained instead if you'd rather skip the root workspace files — minor.)
5. **Launch locales.** **Lean: en-only at launch**, scaffolding ready for ja → de (growth-marketing §1.3). Whyzard already proves the multi-locale path.
6. **`CHANGELOG.md`, `plans/`, `docs/` subdirs.** **RESOLVED:** `CHANGELOG.md` → `apps/ios/LinkClean/CHANGELOG.md` (iOS app-version history; web will grow its own when it ships). Root `plans/` **dissolves into `docs/plans/`** — no second plan home; the merged `docs/plans/` carries both the executable feature plans (SEED, 001/002) and the existing higher-level design docs (analytics, copy-as-you-want, iap-impl, onboarding, parameter-telemetry). `docs/iap/`, `docs/release/`, `docs/dashboards/` move with iOS to `apps/ios/LinkClean/docs/` (pure iOS operations); the rest of `docs/` (`strategy/`, `product/`, `plans/`, `raw/`, `archive/`, `ROADMAP.md`) stays at root.
7. **iOS workspace container shape.** **RESOLVED → `apps/ios/LinkClean/`**, not flat `apps/ios/`. fastlane sits at `apps/ios/LinkClean/fastlane/` (beside its xcodeproj — the Fastfile's CWD-relative `XCODEPROJ` requires this); the iOS `.gitignore` sits one level higher at `apps/ios/.gitignore` so a single file scopes the whole workspace. (Trade-off: the inner path is `apps/ios/LinkClean/LinkClean/` for SwiftUI sources — minor repetition, unambiguous.)
8. **Where do `/privacy-policy` + `/terms` live?** **RESOLVED → stay on `ken0nek.com` permanently** (no migration onto `linkclean.app`). Mirrors `../whyzard/` (same author, same hosting); avoids forcing an iOS resubmission to repoint a URL that points at stable content. Cost is a minor brand-consistency hit on the footer + ASC link; whyzard has lived with it fine. (See §6 "Legal pages".)

---

## 9. Cross-references

- **Reference implementation (mirror this):** `../whyzard/apps/landing/` + its `CLAUDE.md` (stack, i18n, the `/questions/` cluster = our `/trackers/` model, TelemetryDeck Web wiring, the AI-bots zone trap).
- **Why** (owned-web-home thesis, the LP's job): [growth-marketing.md](growth-marketing.md) §2, §5.
- **What** (IA, page templates, content map, build waves, schema): [seo-content-plan.md](seo-content-plan.md) §2–§7. *(Update its §6 stack line: Cloudflare Workers/Hono, not Astro.)*
- **Against whom** (Clean Links' marketing site + web cleaner): [competitor-clean-links.md](competitor-clean-links.md).
</content>
