# LinkClean — Monorepo

A polyglot monorepo for **LinkClean**, the privacy-first URL cleaner for iOS, plus the marketing site that points at it.

## Repository layout

```
linkclean/
├─ apps/
│  ├─ ios/
│  │  └─ LinkClean/        ← the iOS app, its Swift package, extensions, fastlane, screenshots
│  └─ landing/             ← marketing site (Hono on Cloudflare Workers), local-only in Phase 1
├─ docs/                   ← cross-cutting docs: strategy/, product/, plans/, ROADMAP.md, archive/, raw/
├─ apps/ios/LinkClean/docs/
│  ├─ iap/                 ← App Store Connect setup, IAP regional pricing
│  ├─ release/             ← App Store metadata, privacy nutrition label, privacy policy
│  └─ dashboards/          ← TelemetryDeck dashboards
├─ pnpm-workspace.yaml · package.json · tsconfig.base.json · biome.json   ← JS/TS workspace
└─ mise.toml               ← node + pnpm (ruby pin lives at apps/ios/LinkClean/mise.toml)
```

## Working on the iOS app

See [`apps/ios/LinkClean/README.md`](apps/ios/LinkClean/README.md) and [`apps/ios/LinkClean/CLAUDE.md`](apps/ios/LinkClean/CLAUDE.md). Open `apps/ios/LinkClean/LinkClean.xcodeproj` in Xcode; run fastlane from `apps/ios/LinkClean/`.

## Working on the landing site

See [`apps/landing/CLAUDE.md`](apps/landing/CLAUDE.md).

```bash
pnpm install
pnpm --filter @linkclean/landing dev          # wrangler dev on :3001
pnpm --filter @linkclean/landing typecheck    # tsc --noEmit
```

## Why a monorepo

One home for the app + the web property that markets it; shared `docs/`; atomic cross-cutting changes (a tracker added to the catalog *and* its `/trackers/<param>` page in one PR). The infrastructure plan: [`docs/strategy/monorepo-and-landing.md`](docs/strategy/monorepo-and-landing.md).
