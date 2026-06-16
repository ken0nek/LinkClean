# apps/landing

Marketing site for LinkClean — Hono on Cloudflare Workers, mirrors `../../../whyzard/apps/landing/`. Server-rendered (per-locale HTML pre-rendered at worker boot from a single `routes.ts` registry), CSS inlined via `hono/html`'s `raw()`, no client JS, no build step beyond wrangler's bundling. Entry: `src/index.tsx`.

## Phase status

**Phase 3a (current): local Wave-1 site.** Home + `/trackers/` glossary hub + 3 spokes (utm_source / fbclid / gclid) + 2 guides + 2 learn pillars all render under `wrangler dev`. JSON-LD, sitemap, hreflang, llms.txt, robots.txt complete. TelemetryDeck Web is structurally wired but no-ops until `TELEMETRY_APP_ID` is set in `src/brand.ts`. Still no Cloudflare account, no domain, no `deploy:*`. **Phase 3b** (public launch — domain + deploy) and **Phase 3c** (content cadence + ja/de locales) are the next gates. See `docs/strategy/monorepo-and-landing.md`.

## Run

```bash
pnpm --filter @linkclean/landing dev          # wrangler dev on :3001
pnpm --filter @linkclean/landing typecheck    # tsc --noEmit
# Phase 3b only:
# pnpm --filter @linkclean/landing deploy:dev
# pnpm --filter @linkclean/landing deploy:prod
```

## Layout

```
src/
  index.tsx              # Hono app; loops `routes.ts`, pre-renders each entry at boot, /sitemap.xml, /healthz
  routes.ts              # SSoT — { path, render, localesPresent, pathFor, priority }. buildSitemap() reads the same array
  pageLayout.tsx         # shared `<Layout>` shell (head + header + footer + TELEMETRY_INIT)
  styles.ts              # `css` export — inlined as one <style> block via raw()
  page.tsx               # home renderer (renderPage) — Hero + demo + benefits + comparison + surfaces + trackers CTA + FAQ
  brand.ts               # SITE_URL, APP_STORE_ID, AUTHOR, LAST_UPDATED, TELEMETRY_APP_ID (empty until 3a.4)
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

## Phase 3b — what gets added on top

- Domain + Cloudflare deploy (§6 of the plan): buy `linkclean.app`, move DNS, `deploy:prod`. Hub-and-spoke pages already render — only the public surface is missing.
- Submit `/sitemap.xml` to Search Console.
- Migrate `/privacy-policy` / `/terms` / `/support` onto `linkclean.app`; 301 the old `ken0nek.com` URLs; update `fastlane/metadata/en-US/privacy_url.txt` + in-app links in a **post-1.1.0** iOS build.

## Phase 3c — what gets added on top

- Content waves 2–3 (additional tracker spokes, more guides, more learn pillars).
- `ja` + `de` locales: copy modules + `app-store-badge-{ja,de}.svg` in `public/` + each `*/data.ts` entry adopts a `ja` / `de` content key.
- TelemetryDeck Web — create the `linkclean-landing` TD app, set `TELEMETRY_APP_ID` in `src/brand.ts`. The shim in `pageLayout.tsx` already auto-loads the SDK and dispatches `Landing.AppStoreTapped` on every badge click (via the text/plain Blob CORS trick).
- Decide on the `/clean` free web cleaner.

## Cloudflare zone trap (when Phase 3b ships)

Cloudflare's **Security → Bots → Block AI Bots** silently overrides the `robots.txt` allowlist — the edge enforces it before the worker serves anything. Verify it's OFF (and Bot Fight Mode either OFF or with the AI UAs allowlisted). This whole site's LLMO play depends on AI crawlers reaching the content.
