# LinkClean — Monorepo & Landing-Page Build Plan

> **Status: proposed — 2026-06-13.** The **engineering** plan to (a) restructure this repository into a monorepo that absorbs the iOS app and (b) scaffold, deploy, and ship the landing page at **`linkclean.app`**. The infrastructure counterpart to [seo-content-plan.md](seo-content-plan.md) (*what pages to build*) and [growth-marketing.md](growth-marketing.md) §2 / §5 (*why an owned web home, and what the LP must say*). *This doc covers repo structure, the web stack, the migration mechanics, CI, domain/DNS, and sequencing — not content, copy, or SEO (those are the two docs above).*
> **Builds on:** [growth-marketing.md](growth-marketing.md) §2 + §5, [seo-content-plan.md](seo-content-plan.md) §2/§6, [competitor-clean-links.md](competitor-clean-links.md).
> **Reference implementation:** **`../whyzard/apps/landing/`** — the founder's existing, deployed Cloudflare landing site. **We mirror its stack and conventions** (Hono/JSX on Cloudflare Workers, Wrangler, TelemetryDeck Web, the per-locale + content-cluster structure). Per [CLAUDE.md](../../CLAUDE.md) "find the closest existing example and match its pattern" — that example is Whyzard. **This supersedes the abstract "Astro/Next-static" lean in seo-content-plan §6** (which should be updated to match).
> **⚠️ Hard constraint:** iOS **1.0.0 (build 10) is mid App-Store-submission**. Moving the Xcode project / fastlane now risks breaking the release. **⇒ Ship the landing page first; absorb the iOS app into `apps/ios/` only after 1.0 is live.**

---

## 0. Goal & the one decision that drives everything

Priority #3, verbatim: *"Buy linkclean.app, ship the LP + the first SEO/LLMO cornerstone pages. Outside the iOS codebase, compounds for free, the home base for every other channel."*

So **the landing page is the value; the monorepo is the vehicle.** They are separable and carry very different risk:

| Work | Value | Risk / effort | Blocks on |
|---|---|---|---|
| Scaffold + ship `apps/landing/` | **High — the whole point of #3** | Low (greenfield, mirrors a working repo, nothing existing touched) | nothing |
| Move the iOS app into `apps/ios/` | Low (pure tidiness) | **Real** — Xcode refs, the `LinkCleanKit` SPM relative path, fastlane, scripts, screenshot pipeline, and a release in flight | iOS 1.0.0 shipping |

**Therefore: do not big-bang.** Stand up the monorepo skeleton and ship the landing page *while the iOS app stays exactly where it is at the repo root.* Absorb the iOS app in one isolated commit once 1.0 has cleared review. Identical end state; the sequence avoids coupling a marketing launch to a risky project move during a submission.

**Why a monorepo at all:** one home for the app + the web property that markets it; shared `docs/` and brand assets; atomic cross-cutting changes (a tracker added to the catalog *and* its `/trackers/<param>` page in one PR); a single base every channel points back to. **The cost** is the one-time iOS-absorb repath (§4) — paid once, deferred safely.

---

## 1. Target layout

Mirrors `../whyzard/` (a pnpm workspace whose JS apps live under `apps/`). LinkClean adds the iOS app as a sibling app:

```
linkclean/                      ← repo root
├─ apps/
│  ├─ ios/                      ← the entire current iOS app, moved here in Phase 2
│  │  ├─ LinkClean/ · LinkClean.xcodeproj · LinkCleanKit/ (SPM — MUST stay sibling to .xcodeproj)
│  │  ├─ LinkCleanAction/ · LinkCleanMarkdownAction/ · LinkCleanWidget/ · *Tests/
│  │  ├─ fastlane/ · Gemfile · Gemfile.lock · mise.toml · scripts/ · Screenshots/
│  │  └─ ARCHITECTURE.md · CLAUDE.md · AGENTS.md · README.md   (iOS-specific, moved here)
│  └─ landing/                  ← NEW — Hono on Cloudflare Workers (Phase 1), mirrors whyzard/apps/landing
│     ├─ wrangler.jsonc              # worker name, assets dir, dev/prod envs, custom-domain routes
│     ├─ package.json                # "@linkclean/landing"; scripts: dev / deploy:dev / deploy:prod
│     ├─ tsconfig.json               # extends ../../tsconfig.base.json; jsxImportSource: hono/jsx
│     ├─ src/
│     │  ├─ index.tsx                # route registration; pre-renders each page/locale at worker boot
│     │  ├─ page.tsx                 # Page component + inlined OKLCH CSS + JSON-LD builder
│     │  ├─ brand.ts                 # brand constants (URLs, author, App Store link, LAST_UPDATED)
│     │  ├─ copy/                    # per-locale typed Copy modules (en first; ja/de later)
│     │  ├─ i18n/locales.ts          # locale registry + path/url helpers
│     │  └─ trackers/                # the /trackers glossary cluster ── twins whyzard's src/qa/
│     │     ├─ data.ts               #   the authored parameter catalog (one entry per tracker)
│     │     ├─ select.ts             #   hub/spoke resolution (a category hub at N+ spokes)
│     │     └─ paths.ts · chrome.ts  #   path helpers + per-page chrome strings
│     ├─ public/                     # robots.txt (AI allowlist), llms.txt, og/, app-store badge, icon
│     └─ CLAUDE.md                   # web conventions for agents working here
├─ docs/                        ← stays at root; monorepo-wide knowledge base (unchanged)
├─ .github/workflows/           ← stays at root (path-scoped in §5)
├─ pnpm-workspace.yaml          ← NEW (root) — registers apps/landing; mirrors whyzard
├─ package.json                 ← NEW (root) — workspace root
├─ tsconfig.base.json           ← NEW (root) — shared TS base that apps/landing extends
├─ README.md                    ← rewritten as a monorepo overview
├─ CLAUDE.md                    ← monorepo-wide conventions (iOS specifics move to apps/ios/)
└─ .gitignore · .mcp.json · .claude/ · .agents/ · skills-lock.json
```

**What moves vs what stays:**

| Moves into `apps/ios/` (Phase 2) | Stays at repo root |
|---|---|
| `LinkClean/`, `LinkClean.xcodeproj`, `LinkCleanKit/`, the three extensions, both test targets, `*.entitlements` | `.git/`, `.github/`, `.gitignore`, `.mcp.json`, `.claude/`, `.agents/`, `skills-lock.json` |
| `fastlane/`, `Gemfile`, `Gemfile.lock`, `mise.toml`, `scripts/`, `Screenshots/` | `docs/`; the new root `pnpm-workspace.yaml` / `package.json` / `tsconfig.base.json` |
| `ARCHITECTURE.md`, `AGENTS.md`, and the iOS halves of `README.md` / `CLAUDE.md` (split, §4) | the new monorepo-root `README.md` + `CLAUDE.md` |

> Build artifacts (`*.ipa`, `*.dSYM.zip`, `.build/`) are already git-ignored and untouched. Add `node_modules/`, `dist/`, `.wrangler/` to `.gitignore` in Phase 1.
>
> **On the pnpm workspace:** LinkClean has only one JS package today (`apps/landing`), so the root workspace files are mostly for **parity with whyzard** — same `pnpm --filter @linkclean/landing` ergonomics, same `tsconfig.base.json`, room for a future shared package. The Xcode app stays outside the JS workspace entirely (polyglot repo; nothing to orchestrate between Swift and Node).

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

### Phase 1 — Monorepo skeleton + ship the landing page  *(now; zero iOS risk)*
iOS stays at the repo root untouched; we add `apps/` beside it.

1. Add root workspace files (`pnpm-workspace.yaml`, root `package.json`, `tsconfig.base.json`) — copy whyzard's, retarget to `@linkclean/*`. Extend `.gitignore` (`node_modules/`, `dist/`, `.wrangler/`).
2. Scaffold `apps/landing/` from whyzard's `apps/landing/` skeleton: `wrangler.jsonc`, `package.json` (`@linkclean/landing`, `dev`/`deploy:dev`/`deploy:prod` scripts), `tsconfig.json`, `src/{index,page,brand}.tsx`, `src/copy/en.ts`, `src/i18n/locales.ts`, `public/{robots.txt,llms.txt}`. Add `apps/landing/CLAUDE.md`.
3. Build the **Wave-1 cornerstones only** (seo-content-plan §7): Home/LP, `/trackers` hub, "What's hidden in a share link?", `utm`/`fbclid`/`gclid` explainers, "How to remove UTM parameters", "How to clean a YouTube link", "Do cleaned links still work?". Wire `sitemap.xml`, canonical/hreflang, OG + JSON-LD (seo-content-plan §6).
4. Local dev: `pnpm --filter @linkclean/landing dev` (wrangler dev). Deploy dev: `deploy:dev` → `linkclean-landing-dev.workers.dev` to QA.
5. **Domain + production deploy** (§6): buy `linkclean.app`, move DNS to Cloudflare, then `deploy:prod` with the `custom_domain` routes. Verify HTTPS + the **Block-AI-Bots-OFF** zone check.
6. **Done when:** `https://linkclean.app` serves the LP + Wave-1 pages over HTTPS, sitemap submitted to Search Console, CTA → App Store works, TelemetryDeck Web recording impressions + taps.

### Phase 2 — Absorb the iOS app into `apps/ios/`  *(after iOS 1.0.0 is live)*
A single isolated PR doing only the move (§4). No feature work mixed in — keep the diff reviewable and the revert trivial.

### Phase 3 — Follow-ons  *(post-launch, compounding)*
- Migrate `/privacy-policy`, `/terms`, `/support` onto `linkclean.app` (§6); 301 the old `ken0nek.com` URLs.
- Content Waves 2–3 (seo-content-plan §7) at a steady 2–4 pages/week; add `ja` → `de` locales.
- Decide on the `/clean` free web cleaner (seo-content-plan §9 / §8-3 below).

---

## 4. iOS absorb — migration mechanics (the risky part, spelled out)

Run as one PR, **only after 1.0 ships.** Verified facts about the blast radius:

- **`LinkClean.xcodeproj` references the package as `relativePath = LinkCleanKit`** (a sibling). Moving the `.xcodeproj` **and** `LinkCleanKit/` **together** into `apps/ios/` preserves that path — **no pbxproj edit needed** for the package link.
- The **only** non-build-product paths in `project.pbxproj` are `../../Frameworks` *build-setting* values (relative to the build products dir, not the source tree) — unaffected by the folder move.
- **There is no iOS build CI to repath** — `.github/` is only the two Claude automation workflows (§5).

Steps:

1. **`git mv` the §1 "moves" column into `apps/ios/`** in one commit (preserves history). Move `LinkClean.xcodeproj` and `LinkCleanKit/` in the same operation so they stay siblings.
2. **Open in Xcode once** to re-resolve the package and fix any stray red refs; confirm all targets + schemes build.
3. **fastlane** moves into `apps/ios/fastlane/` (run `bundle exec fastlane` from `apps/ios/`); `Gemfile`/`Gemfile.lock`/`mise.toml` alongside. Do a **`deliver --verify_only`-style dry run** — fastlane is the likeliest to hold an implicit path assumption.
4. **`scripts/` + `Screenshots/`:** repath any hardcoded scheme/project references (`scripts/capture-raw-screenshots.sh`, the Screenshots composer).
5. **Docs split:** `ARCHITECTURE.md`/`AGENTS.md` → `apps/ios/`. **`CLAUDE.md`:** current iOS rules → `apps/ios/CLAUDE.md`; a slim **root `CLAUDE.md`** describes the monorepo (Claude Code reads them hierarchically, so iOS rules still apply inside `apps/ios/`, web rules inside `apps/landing/`). **`README.md`:** iOS content → `apps/ios/README.md`; new root README = monorepo overview.
6. **Verify gates (all green before merge):** kit fast lane (`swift test` in `apps/ios/LinkCleanKit/`), app tests (`xcodebuild test -scheme LinkCleanTests` on an OS-26.4 sim), a **Release** build (the `.storekit`-in-bundle exception + signing are fragile), and the fastlane dry run.

---

## 5. CI & deploy

**Today:** no iOS build pipeline. `.github/` has only `claude.yml` (`@claude` mentions) and `claude-code-review.yml` (auto-review on **every** `pull_request`, no path filter). Neither breaks on the iOS move.

**Add with the monorepo:**
- **Deploy = Wrangler, not a host git-integration.** Like whyzard, deploys are CLI: `pnpm --filter @linkclean/landing deploy:prod` (`wrangler deploy --env production`). Manual is fine to start; optionally add a GitHub Action later that runs `wrangler deploy` on push to `apps/landing/**`.
- **Path-scope the auto-review** (`claude-code-review.yml` `paths:`) so landing PRs aren't reviewed through an iOS lens and vice-versa. Cheap, low priority.
- Optional tiny `apps/landing/**`-scoped "typecheck + build" Action so a broken worker can't merge. Defer until the site has enough pages to warrant it.

---

## 6. Domain, DNS & privacy/legal

**Your plan: buy `linkclean.app` on Squarespace, run DNS on Cloudflare.** Registration stays at Squarespace; only DNS authority moves to Cloudflare (which is all the `custom_domain` routes need). Steps:

1. Buy `linkclean.app` at Squarespace Domains.
2. Cloudflare dashboard → **Add a site** → `linkclean.app` → Free plan → it returns two Cloudflare nameservers.
3. At Squarespace, replace the domain's nameservers with those two. Wait for Cloudflare to mark the zone **Active**.
4. `deploy:prod`: the production `routes` block (`{ pattern: "linkclean.app", custom_domain: true }` + `www`) **auto-provisions the cert + DNS records** — no manual CNAME (exactly whyzard's setup). `.app` is HSTS-preloaded → HTTPS is mandatory and now automatic; **never serve http**.
5. ⚠️ **Cloudflare zone silently overrides `robots.txt`.** In **Security → Bots**, verify **"Block AI Bots" is OFF** and Bot Fight Mode is OFF (or allowlists the AI UAs). The edge enforces these *before* the worker serves `robots.txt` — an open allowlist file is meaningless otherwise, and this whole play depends on AI crawlers reaching the `/trackers` pages (growth-marketing §3 / seo-content-plan §6). *(Whyzard's own CLAUDE.md flags this exact trap.)*
6. *(Optional, later: transfer registration to Cloudflare Registrar for at-cost renewal — Cloudflare requires the zone to live there ~60 days first.)*

**Legal pages:** the app's privacy URL currently resolves to `https://ken0nek.com/apps/linkclean/privacy-policy/` and was *just* reconciled for review — **don't repoint it mid-submission.** Phase 3: publish `/privacy-policy` + `/terms` + `/support` on `linkclean.app`, 301 the old URLs, then update `fastlane/metadata/en-US/privacy_url.txt` + in-app links in a *later* iOS build.

---

## 7. Definition of done

- **Phase 1:** `linkclean.app` live over HTTPS via the `linkclean-landing` worker; LP + Wave-1 pages published; sitemap in Search Console; AI-bots zone check passed; every CTA → App Store; TelemetryDeck Web recording; `apps/landing/` builds from a fresh clone (`pnpm install && pnpm --filter @linkclean/landing dev`); iOS app at repo root still green (untouched).
- **Phase 2:** iOS lives under `apps/ios/`; all verify gates green (kit fast lane, app tests, Release build) + fastlane dry run; history preserved; root README/CLAUDE split done.
- **Phase 3:** legal pages on `linkclean.app` with 301s; ASC + in-app privacy URLs updated in a post-1.0 build; content cadence running.

---

## 8. Open decisions

1. **Hosting / stack.** **RESOLVED → Cloudflare Workers + Wrangler + Hono, mirroring `whyzard/apps/landing`.** (Supersedes the Astro/Pages/Plausible I first floated and the "Astro" line in seo-content-plan §6 — flagged there for update.)
2. **Move iOS now vs after 1.0.** **Lean: after 1.0** — the submission-in-flight constraint (§0) makes this near-unarguable; Phase 1 doesn't need the move.
3. **Build the `/clean` free web cleaner in Phase 1?** Strong SEO/LLMO magnet + conversion pivot, but gives the core away free (seo-content-plan §9-1). **Lean: not in Phase 1** — ship content cornerstones first; add `/clean` as a Hono island once there's traffic to convert.
4. **pnpm workspace for a single JS package?** Mild overkill today, but it's **parity with whyzard** at trivial cost. **Lean: yes, mirror it.** (Keep `apps/landing` self-contained instead if you'd rather skip the root workspace files — minor.)
5. **Launch locales.** **Lean: en-only at launch**, scaffolding ready for ja → de (growth-marketing §1.3). Whyzard already proves the multi-locale path.

---

## 9. Cross-references

- **Reference implementation (mirror this):** `../whyzard/apps/landing/` + its `CLAUDE.md` (stack, i18n, the `/questions/` cluster = our `/trackers/` model, TelemetryDeck Web wiring, the AI-bots zone trap).
- **Why** (owned-web-home thesis, the LP's job): [growth-marketing.md](growth-marketing.md) §2, §5.
- **What** (IA, page templates, content map, build waves, schema): [seo-content-plan.md](seo-content-plan.md) §2–§7. *(Update its §6 stack line: Cloudflare Workers/Hono, not Astro.)*
- **Against whom** (Clean Links' marketing site + web cleaner): [competitor-clean-links.md](competitor-clean-links.md).
</content>
