# LinkClean TODO

## 1.0.0

In priority order:

1. [x] Fix Google Maps link sharing issue — only unknown-scope item; core share-sheet flow
2. [x] Add analytics using TelemetryDeck — plan: [docs/plans/analytics.md](plans/analytics.md); §6/§7 taxonomy implemented across app + both action extensions (`AnalyticsService`/`AnalyticsEvent` in LinkCleanKit)
3. [x] Initial onboarding — plan: [docs/plans/onboarding.md](plans/onboarding.md); funnel events now wired (`Onboarding.Flow.completed`/`skipped`, `Onboarding.ExtensionGuide.shown`)
   - [x] Instruction to add action extension (how to enable it in the share sheet) — interactive `ExtensionGuideView`, shown in onboarding and from Settings
4. [x] Action extension icon asset per extension — needed before share-sheet screenshots
   - [x] LinkCleanAction
   - [x] LinkCleanMarkdownAction
5. [x] Screenshots for App Store Connect — captioned 1.0.0 set (Home / History / Parameters × iPhone 6.9″ / iPad 13″): committed raws in `screenshots/raw/en-US/` + the `LinkCleanScreenshots` composer target → App Store-ready PNGs in `fastlane/screenshots/en-US/` (gitignored); pipeline in `docs/release/app-store-metadata.md`. Post-1.0 enrichment: a share-sheet "Clean Link" shot
6. [ ] Metadata (App Store Connect) — privacy nutrition label depends on TelemetryDeck (2)
7. [ ] Privacy policy — required for App Store submission; draft ready at [ken0nek.com/apps/linkclean/privacy-policy](https://ken0nek.com/apps/linkclean/privacy-policy/), publish before metadata (6)

Open decisions:

- [ ] **Buy the `linkclean.app` domain?** Not a launch blocker — the App Store URLs work today (support → `github.com/ken0nek`, privacy → `ken0nek.com/apps/linkclean`). A dedicated `.app` domain (cf. `whyzard.app`) would give a marketing/landing front door and cleaner support + universal-link URLs, at the cost of registration + mandatory HTTPS. Metadata URLs are editable post-launch, so this can wait. If bought, revisit the support/marketing/privacy URLs.

Added during 1.0.0 (beyond the original priority list):

- [x] **Cleaning transparency on Home** — after a URL is entered or auto-pasted and cleaned, show the user what happened. Asymmetric by design: the *leftover* side is actionable, the *removed* side is read-only.
  - **Leftover (actionable):** surface *every* parameter that survived cleaning as tappable pills — not just reference-catalog trackers (chose max visibility/control on 2026-06-08; arbitrary keys like `test` surface too, via `URLCleaner.leftoverParameterNames`). Tapping one opens a confirm dialog, then adds it to custom tracking parameters (`addCustomParameter`) so it's stripped from then on. The confirm step is the guardrail against globally blocklisting a functional param (`id`, `q`). Raw leftover names are display-only/on-device — never sent; telemetry still uses only `referenceMatches`.
    - Section header "Remaining" + prompt "Tap a parameter to always remove it from your links." Confirm: "Always remove this parameter?" / "“%@” will be removed from your links from now on."
  - **Removed (informational only):** a calm proof-of-work summary — "3 trackers removed," expandable to names. No undo CTA. Rationale: the moment we invite scrutiny on what we removed, we owe the user an undo we're not offering — and transparency builds trust without it (cf. ad blockers' "X trackers blocked").
  - **Restore / per-user allow-list: explicitly out of scope.** Over-cleaning is wrong *for everyone*, so the fix belongs in the default catalog (informed by the catalog-gap / novel-tail telemetry already collected), not a per-user keep-list that adds a confusing second mental model ("strip these… but keep these…"). Revisit only if telemetry shows over-cleaning is both real and uncatchable by catalog curation.
  - **Most detection already exists:** `URLCleaner.cleanResult` returns `removedCount`, `removedKindIDs`, `leftoverCount`, `referenceMatches`. Gap: the result carries counts/kind-IDs (privacy-safe for telemetry), not raw param names — the Home VM can derive names locally from the URL it already holds. Keep raw names out of analytics events.

Done:

- [x] App icon revamp

Out of scope for this version:

- No localization (identifier-key mechanism is in place; translations come later)
- No IAP

## 1.1.0

- [~] IAP using **StoreKit 2** (was RevenueCat) — code shipped 2026-06-10 (custom paywall + T1–T4 gates + 7-day/1-rule free tier, no grandfathering); ⛔ blocked on App Store Connect setup → [docs/iap/app-store-connect-setup.md](iap/app-store-connect-setup.md). Plan: [docs/plans/iap-implementation-plan.md](plans/iap-implementation-plan.md)
- [x] IAP strategy (pricing, premium features, free tier limitations) — [docs/strategy/iap-strategy.md](strategy/iap-strategy.md)
- [ ] Terms of use — required once IAP ships (Apple EULA requirement); draft ready at [ken0nek.com/apps/linkclean/terms-of-use](https://ken0nek.com/apps/linkclean/terms-of-use/)
