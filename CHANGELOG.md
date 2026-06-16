# Changelog

All notable changes to LinkClean, newest first. Versions are App Store marketing
versions ([SemVer](https://semver.org/)); the format follows
[Keep a Changelog](https://keepachangelog.com/). User-facing store copy lives in
`fastlane/metadata/en-US/release_notes.txt`, product-decision rationale in
[ARCHITECTURE.md](ARCHITECTURE.md), and what's next in
[docs/ROADMAP.md](docs/ROADMAP.md).

## [1.1.0] — Submitted 2026-06-16 (awaiting App Store review)

Tag `1.1.0` (`cd0391d`); 47 commits since 1.0.0.

### Added

- **Clean from anywhere** — Shortcuts, Siri, Control Center, and a Home Screen widget, alongside the existing Share Sheet.
- **QR codes** — scan a QR to clean the link inside it, or generate a QR from a cleaned link. Home's "Share as QR" button is behind an opt-in Setting.
- **Redirect unwrapping** — follow wrapper/redirect links to the real destination before cleaning, surfaced with a note on Home.
- **Fragment cleaning** — strip trackers and scroll-to-text (`#:~:text=`) directives after the `#`, with a default-on toggle to keep scroll-to-text.
- **On-device tracker advisor** — flags the likely trackers among the parameters left behind, so you decide what to remove. Runs fully on device.
- **Statistics dashboard** — see your cumulative cleaning impact, plus a privacy card you can share.
- **Copy as you want** — copy links as plain text, Markdown, or your own templates, with an in-extension format picker.
- **Localization** — Japanese and German, plus a copy pass across English.

### Changed

- Larger, regrouped tracking-parameter catalog (more parameters stripped; categories regrouped — pixels→ads, HubSpot→analytics, common→referral).
- The Markdown-only Copy action is now the template-driven "Copy link as…" picker; custom formats are a Pro feature on the paywall.

### Internal

- Architecture proposals 1–13: `CleanOutcome`/`CleanSession`, an `AppDependencies` composition root, `ActionPipeline` + strategies (replacing base-class inheritance), `HistoryStore`, `EntitlementsProviding`; `ARCHITECTURE.md` rewritten to the as-built system.
- `LinkCleanKit` split into four layered targets (Core / Data / Analytics / ExtensionUI) with compiler-enforced dependency direction.
- Two-speed test split: a macOS fast lane (<1s) plus `LinkCleanTestSupport`.
- Lifetime statistics counters: silent App Group aggregates feeding the dashboard.
- Analytics instrumentation: `Stats.*`, paywall conversion sliced by the gate that raised it, QR export tracking, per-surface clean attribution, and the catalog-gap loop fed from every clean surface.
- Build/release: Ruby pinned to 3.4.8, widget extension versioned in the fastlane bump lanes, simulator runtime retargeted to iOS 26.5, widget privacy manifest + shared scheme.

## [1.0.0] — 2026-06-15

Initial public release.

### Added

- Clean tracking parameters from any link — paste it in or use the Share Sheet ("Clean URL" and "Copy as Markdown" actions).
- Cleaning transparency on Home: a read-only summary of what was removed, plus every leftover parameter as a tappable pill you can promote to an always-remove rule (see [ARCHITECTURE.md](ARCHITECTURE.md) for the no-undo / no-restore rationale).
- Searchable History of everything you've cleaned.
- 100% on-device cleaning — the full links you clean never leave your device.
- **LinkClean Pro** (StoreKit 2, no subscription): custom rules and your full History archive, behind a custom paywall with a free tier (1 rule / 7-day window). One-time purchase, no grandfathering.
- Onboarding with an interactive guide for enabling the Share Sheet extension.
- Privacy-safe TelemetryDeck analytics (typed, on-device event taxonomy; no raw URLs or parameter names).
