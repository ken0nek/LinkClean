# apps/landing

Marketing site for LinkClean — Hono on Cloudflare Workers, mirrors `../../../whyzard/apps/landing/`. Server-rendered (per-locale HTML pre-rendered at worker boot), CSS inlined in `src/page.tsx` via `hono/html`'s `raw()`, no client JS, no build step beyond wrangler's bundling. Entry: `src/index.tsx`.

## Phase status

Phase 1 (current): **local-only placeholder** — Home page + `/healthz`. No Cloudflare account, no domain, no `deploy:*`. Phase 3 adds Wave-1 content, JSON-LD, sitemap, hreflang, TelemetryDeck Web, and the production deploy. See `docs/strategy/monorepo-and-landing.md`.

## Run

```bash
pnpm --filter @linkclean/landing dev          # wrangler dev on :3001
pnpm --filter @linkclean/landing typecheck    # tsc --noEmit
# Phase 3 only:
# pnpm --filter @linkclean/landing deploy:dev
# pnpm --filter @linkclean/landing deploy:prod
```

## Layout

```
src/
  index.tsx              # Hono app; pre-renders each locale at boot, /healthz
  page.tsx               # Page renderer + inlined CSS
  brand.ts               # brand constants (SITE_URL, APP_STORE_ID, AUTHOR, LAST_UPDATED, …)
  copy/
    types.ts             # Copy interface (source of truth for the shape)
    en.ts                # English copy (ja, de drop in here in Phase 3)
  i18n/
    locales.ts           # LOCALES, DEFAULT_LOCALE, LOCALE_LIST, localePath, localeUrl
public/
  robots.txt             # AI-crawler allowlist (Cloudflare zone must NOT block AI bots)
  llms.txt               # LLM brand brief
  # Phase 3: app-store-badge-en.svg, og/, linkclean-icon.png
```

## Conventions (inherited from whyzard)

- **No build step.** `wrangler dev` bundles `src/index.tsx` on the fly. No vite/esbuild config.
- **Per-locale at boot.** `index.tsx` loops `LOCALE_LIST` and pre-renders one HTML string per locale, then registers route handlers serving them. Static per locale — keeps the worker cold-start fast.
- **CSS inlined.** One `<style>` block in `page.tsx` passed through `raw()` so `&` nesting and `>` child combinators aren't escaped. No webfonts.
- **Wrangler envs.** `development` → `linkclean-landing-dev`; `production` → `linkclean-landing` with custom-domain routes for `linkclean.app` + `www.linkclean.app`. Phase 1 never runs `deploy:*`.

## Phase 3 — what gets added on top

- Wave-1 cornerstones (Home expansion + `/trackers/` hub + spokes + explainers — see `docs/strategy/seo-content-plan.md` §7).
- JSON-LD: `SoftwareApplication` (home) + `Article`+`FAQPage` (trackers/learn) + `HowTo` (guides) + `DefinedTermSet` (glossary).
- Per-locale `<head>` chrome: hreflang, `og:locale`, canonical (already partially wired).
- `/sitemap.xml` (built at boot — see whyzard's `buildSitemap()` for the pattern).
- TelemetryDeck Web — copy whyzard's `TELEMETRY_INIT` verbatim, separate `linkclean-landing` TD app, the `text/plain` Blob CORS trick for the `AppStoreTapped` signal.
- `ja` and `de` locales (LinkClean ships in those; landing copy can follow).
- Apple's official localized App Store badge SVGs in `public/app-store-badge-<locale>.svg`.

## Cloudflare zone trap (when Phase 3 ships)

Cloudflare's **Security → Bots → Block AI Bots** silently overrides the `robots.txt` allowlist — the edge enforces it before the worker serves anything. Verify it's OFF (and Bot Fight Mode either OFF or with the AI UAs allowlisted). This whole site's LLMO play depends on AI crawlers reaching the content.
