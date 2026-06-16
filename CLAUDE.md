# LinkClean monorepo

A polyglot repo: the iOS app + tooling lives under `apps/ios/LinkClean/`; the marketing site under `apps/landing/`. The two ship independently and share no build steps — pnpm workspace runs the JS side; Xcode/SPM/fastlane run the iOS side.

## Where to find the rules

Claude Code reads CLAUDE.md hierarchically, deepest first. Don't restate per-app rules here.

- **iOS work** → [`apps/ios/LinkClean/CLAUDE.md`](apps/ios/LinkClean/CLAUDE.md) (Swift 6.2, MainActor default, the LinkCleanKit layering, SwiftData/Observation patterns, fastlane).
- **Landing work** → [`apps/landing/CLAUDE.md`](apps/landing/CLAUDE.md) (Hono on Cloudflare Workers, per-locale boot rendering, no client JS, Phase-1 placeholder vs Phase-3 expansion).

## Cross-cutting rules

### Git hygiene
- Only commit staged changes. Never stage additional files unless explicitly asked.
- On unpushed branches, prefer squashing decision-churn commits into the final state rather than leaving them in history.
- Version bumps belong in version-only commits; fastlane's xcodeproj gem inserts pbxproj noise (`exceptions = ()`) — hand-edit the `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` lines instead.

### Toolchain
`mise.toml` is split: root pins `node` + `pnpm` (for `apps/landing` and any future JS package); `apps/ios/LinkClean/mise.toml` pins `ruby` (for fastlane). Mise resolves hierarchically, so each surface sees the right tools without manual switching.

### Docs
Cross-cutting docs (strategy, product decisions, executable feature plans, ROADMAP) stay at `docs/` at the root. Pure-iOS operations docs (App Store Connect setup, release metadata, TelemetryDeck dashboards) live under `apps/ios/LinkClean/docs/`. New design or strategy work goes at the root; new App-Store-Connect-or-fastlane runbooks go in the iOS workspace.

### Off-limits
- Don't touch `apps/ios/LinkClean/fastlane/` mid-review — if an App Store submission is in flight, fastlane must remain in a known-good state in case a rejection needs a fix build.
- Don't introduce a JS dependency that requires running build scripts (postinstall) without adding it to `pnpm-workspace.yaml`'s `onlyBuiltDependencies`.
