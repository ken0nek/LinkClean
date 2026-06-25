# LinkClean Roadmap

Forward-looking only — what's planned, parked, or undecided. Shipped work is in
[CHANGELOG.md](../CHANGELOG.md); product-decision rationale is in
[ARCHITECTURE.md](../ARCHITECTURE.md).

> **Live releases (as of 2026-06-25):** 1.0.0 (2026-06-15), 1.1.0 (2026-06-16), 1.2.0 (2026-06-18 — E4 short-link expansion), and 1.2.1 (2026-06-23 — onboarding Pro step; the ai-A parameter advisor hidden behind a DEBUG flag). 1.1.0 ended up much bigger than originally scoped — most of the planned 1.2 release pulled forward into 1.1; see [product/growth-roadmap.md](product/growth-roadmap.md) §9 "Why this collapsed".

## Backlog (planned, not yet shipped)

- [ ] **ai-C smart titles** — on-device title generation for cleaned links; plan: [plans/001-ai-c-smart-titles.md](plans/001-ai-c-smart-titles.md) (in-app v1; action-extension use deferred). Did not make 1.2.0/1.2.1; **deferred pending a Foundation Models appetite call** — the ai-A parameter advisor was hidden behind a DEBUG flag in 1.2.1, so the next visible FM bet is not committed.
- [x] ~~**E4 short-link expansion**~~ — **shipped in 1.2.0** (2026-06-18): opt-in expansion of t.co / bit.ly and other shorteners (networked; deliberately excluded from the offline redirect unwrapper), **free for all tiers**, default off. Plan: [plans/002-e4-short-link-expansion.md](plans/002-e4-short-link-expansion.md).

## Open decisions

- ✅ **Buy the `linkclean.app` domain + landing page** — **Decided yes 2026-06-16**: domain bought, DNS on Cloudflare, landing site LIVE at [`linkclean.app`](https://linkclean.app/). Build plan + runbook: [docs/strategy/monorepo-and-landing.md](strategy/monorepo-and-landing.md). The "revisit support/marketing/privacy URLs" follow-up: **legal pages stay on `ken0nek.com` permanently** (see monorepo-and-landing.md §8); marketing URL still empty in ASC (optional); support URL still `github.com/ken0nek`.

## Parked (won't do unless data says otherwise)

- **Restore / per-user allow-list for over-cleaning** — out of scope by design; the fix for over-cleaning belongs in the default catalog, not a per-user keep-list. Revisit only if catalog-gap telemetry shows over-cleaning that curation can't catch. Full rationale in [ARCHITECTURE.md](../ARCHITECTURE.md).

## Nice-to-have (not version-pinned)

- [ ] Share-sheet "Clean Link" screenshot to enrich the App Store set; pipeline in [apps/ios/LinkClean/docs/release/app-store-metadata.md](../apps/ios/LinkClean/docs/release/app-store-metadata.md).

## Background & proposal docs

The fuller exploration behind the items above — mostly **proposed / draft** status, not commitments. Start here when scoping a release.

**Product direction**

- [product/growth-roadmap.md](product/growth-roadmap.md) — the full product-growth roadmap (engine depth · OS surfaces · visible value · markets), versioned 1.1 → 2.0. This lean roadmap distills its near-term items.
- [product/ai-features.md](product/ai-features.md) — on-device Foundation Models strategy: which AI features (parameter advisor, history tagging, title refinement, NL search), their free-vs-Pro placement, and the standing "never" constraints.
- [product/wwdc26-proposals.md](product/wwdc26-proposals.md) — WWDC 2026 API-adoption candidates (Foundation Models, `@Query(sectionBy:)`, the `@State` macro migration, Core AI), prioritized.

**Growth & go-to-market**

- [strategy/growth-marketing.md](strategy/growth-marketing.md) — demand generation across ASO, SEO, LLMO, paid, and the "wow" features that market themselves.
- [strategy/seo-content-plan.md](strategy/seo-content-plan.md) — the per-tracker content site at `linkclean.app`: page map, templates, and build order.
- [strategy/competitor-clean-links.md](strategy/competitor-clean-links.md) — deep-dive on the market leader (Clean Links / Numen) and the read for LinkClean.
- [strategy/monorepo-and-landing.md](strategy/monorepo-and-landing.md) — landing-page build plan (also linked under Open decisions above).

**Strategy & measurement** (what the growth docs build on)

- [strategy/iap-strategy.md](strategy/iap-strategy.md) — what to sell: pricing, free-tier limits, gating rules, paywall triggers. The shipped IAP came from here; later Pro tiers are still proposed.
- [strategy/kpis.md](strategy/kpis.md) — the measurement layer: north star, funnel, and what number triggers what action.

**Architecture**

- [archive/ARCHITECTURE_PROPOSALS.md](archive/ARCHITECTURE_PROPOSALS.md) — the from-scratch redesign assessment (proposals 1–13, **largely implemented**; the as-built system lives in [ARCHITECTURE.md](../ARCHITECTURE.md)). Archived, kept for refactoring rationale.
