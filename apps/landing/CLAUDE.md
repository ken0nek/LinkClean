# apps/landing

Marketing site for LinkClean — Hono on Cloudflare Workers, mirrors `../../../whyzard/apps/landing/`. Server-rendered (per-locale HTML pre-rendered at worker boot from a single `routes.ts` registry), CSS inlined via `hono/html`'s `raw()`, no client JS, no build step beyond wrangler's bundling. Entry: `src/index.tsx`.

## Phase status

**Phase 3b ✅ SHIPPED 2026-06-16 — site is LIVE at `linkclean.app`.** Phases 3a (build) and 3b (deploy) complete: home + `/trackers/` glossary hub (36 spokes) + multiple guides + multiple learn pillars, JSON-LD, sitemap, hreflang, llms.txt, robots.txt, TelemetryDeck Web (`TELEMETRY_APP_ID` set in `src/brand.ts`). **Phase 3c (current)** = content cadence (Wave-2/3) + `ja` / `de` locales + `/clean` web cleaner decision. See `docs/strategy/monorepo-and-landing.md`.

## Run

```bash
pnpm --filter @linkclean/landing dev          # wrangler dev on :3001
pnpm --filter @linkclean/landing typecheck    # tsc --noEmit
pnpm --filter @linkclean/landing verify-links # internal-link graph gate (added with the 36-spoke scale)
pnpm --filter @linkclean/landing deploy:dev   # Cloudflare Worker dev env
pnpm --filter @linkclean/landing deploy:prod  # production (linkclean.app)
```

## Layout

```
src/
  index.tsx              # Hono app; loops `routes.ts`, pre-renders each entry at boot, /sitemap.xml, /healthz
  routes.ts              # SSoT — { path, render, localesPresent, pathFor, priority }. buildSitemap() reads the same array
  pageLayout.tsx         # shared `<Layout>` shell (head + header + footer + TELEMETRY_INIT)
  styles.ts              # `css` export — inlined as one <style> block via raw()
  page.tsx               # home renderer (renderPage) — Hero + demo + benefits + comparison + surfaces + trackers CTA + FAQ
  markdown.ts            # tiny inline markdown helper used by tracker spokes / guides / learn (escape + raw())
  brand.ts               # SITE_URL, APP_STORE_ID, AUTHOR, LAST_UPDATED, TELEMETRY_APP_ID
  copy/
    types.ts             # `Copy` interface (the source of truth for the shape)
    en.ts                # English copy (ja, de drop in here in Phase 3c)
  i18n/
    locales.ts           # LOCALES, DEFAULT_LOCALE, LOCALE_LIST, localePath, localeUrl
  trackers/              # the /trackers/ glossary cluster (mirrors whyzard's src/qa/)
    types.ts data.ts chrome.ts paths.ts select.ts render.tsx
  guides/                # /guides/ HowTo articles (Template B)
    types.ts data.ts paths.ts render.tsx
  learn/                 # /learn/ pillar explainers (Template E)
    types.ts data.ts paths.ts render.tsx
public/
  robots.txt             # AI-crawler allowlist (Cloudflare zone must NOT block AI bots — see §6 of the plan)
  llms.txt               # LLM brand brief — facts, surfaces, citable claims, glossary links
  app-store-badge-en.svg # Apple's official badge (ja/de added in Phase 3c)
  linkclean-icon.png     # Source: iOS app icon (1024×1024); used as favicon + og:image
```

## Conventions (inherited from whyzard, adapted)

- **No build step.** `wrangler dev` bundles `src/index.tsx` on the fly. No vite/esbuild config.
- **Single source of truth for routes.** `routes.ts` enumerates every page; `index.tsx` loops it; `buildSitemap()` reads the same array. To add a page, add to the relevant `*/data.ts` and the route + sitemap entry appear automatically.
- **Per-locale at boot.** Each route entry is pre-rendered once; route handlers serve the precomputed HTML string. Static per locale — keeps the worker cold-start fast.
- **CSS inlined.** One `<style>` block from `styles.ts` passed through `raw()` so `&` nesting and `>` child combinators aren't escaped. No webfonts.
- **JSON-LD per template.** Home: `SoftwareApplication` + `FAQPage`. `/trackers/` hub: `DefinedTermSet` + `BreadcrumbList`. `/trackers/<slug>/`: `Article` + `FAQPage` + `BreadcrumbList`. `/guides/<slug>/`: `HowTo` + `BreadcrumbList`. `/learn/<slug>/`: `Article` + `FAQPage` + `BreadcrumbList`.
- **TL;DR discipline.** Every non-home, non-hub page leads with an `<aside class="tldr">` callout. Vital for both SERP snippets and LLM citation.
- **Internal-link discipline.** Each tracker spoke links UP to `/trackers/` (via breadcrumb), ACROSS to ≥2 sibling spokes (via `related`), and OUT to the App Store. Guides and learn pages cross-link to ≥1 tracker.
- **Wrangler envs.** `development` → `linkclean-landing-dev`; `production` → `linkclean-landing` with custom-domain routes for `linkclean.app` + `www.linkclean.app`. Phase 3a never runs `deploy:*`.

## Adding content

- **A new tracker spoke** — append a `TrackerSpoke` to `src/trackers/data.ts` (param, kind, vendor, content per locale). The hub auto-lists it under the right kind grouping. Add reciprocal slugs to `related` on a few existing spokes so the link graph stays dense.
- **A new guide** — append a `GuideArticle` to `src/guides/data.ts` (slug + per-locale `GuideContent` with `tldr`, `steps`, optional `intro`/`outro`/`related`). JSON-LD `HowTo` builds itself from `steps`.
- **A new learn pillar** — append a `LearnArticle` to `src/learn/data.ts` (slug + per-locale `LearnContent` with `tldr`, `sections[{heading, paragraphs, bullets?}]`, optional `faq` and `related`).
- **A new locale** — add the language file to `src/copy/` and register it in `src/i18n/locales.ts`. Every content module (`trackers/data.ts`, `guides/data.ts`, `learn/data.ts`) is keyed by locale and only emits pages for locales it has content for, so a new locale won't 500 — it just won't appear until you author each page.

## Phase 3b — ✅ SHIPPED 2026-06-16

- ✅ Domain + Cloudflare deploy (§6 of the plan): bought `linkclean.app`, moved DNS, `deploy:prod` runs. As-executed runbook lives in `docs/strategy/monorepo-and-landing.md` §6.
- Still to do: submit `/sitemap.xml` to Search Console.
- **Legal pages stay on `ken0nek.com` permanently** (decided 2026-06-16, see [monorepo-and-landing.md](../../docs/strategy/monorepo-and-landing.md) §8 / §11 #4). Privacy + Terms shipped with 1.0.0 and re-shipped with 1.1.0 (both LIVE) pointing at `ken0nek.com/apps/linkclean/{privacy-policy,terms-of-use}/`; we don't migrate them to avoid forcing an iOS resubmission to repoint a URL whose contents don't change. The landing footer already links the same `ken0nek.com` paths via `src/brand.ts` (`PRIVACY_URL` / `TERMS_URL`).

## Phase 3c — what gets added on top

- Content waves 2–3 (additional tracker spokes, more guides, more learn pillars).
- `ja` + `de` locales: copy modules + `app-store-badge-{ja,de}.svg` in `public/` + each `*/data.ts` entry adopts a `ja` / `de` content key.
- Decide on the `/clean` free web cleaner.

## Cloudflare zone trap

Cloudflare's **Security → Bots → Block AI Bots** silently overrides the `robots.txt` allowlist — the edge enforces it before the worker serves anything. It must stay OFF (and Bot Fight Mode either OFF or with the AI UAs allowlisted). Re-verify after any Cloudflare dashboard change: this whole site's LLMO play depends on AI crawlers reaching the content.
