# LinkClean TODO

## 1.0.0 — ✅ Shipped (live on the App Store, Jun 15 2026)

In priority order:

1. [x] Fix Google Maps link sharing issue — only unknown-scope item; core share-sheet flow
2. [x] Add analytics using TelemetryDeck — plan: [docs/plans/analytics.md](plans/analytics.md); §6/§7 taxonomy implemented across app + both action extensions (`AnalyticsService`/`AnalyticsEvent` in LinkCleanKit)
3. [x] Initial onboarding — plan: [docs/plans/onboarding.md](plans/onboarding.md); funnel events now wired (`Onboarding.Flow.completed`/`skipped`, `Onboarding.ExtensionGuide.shown`)
   - [x] Instruction to add action extension (how to enable it in the share sheet) — interactive `ExtensionGuideView`, shown in onboarding and from Settings
4. [x] Action extension icon asset per extension — needed before share-sheet screenshots
   - [x] LinkCleanAction
   - [x] LinkCleanMarkdownAction
5. [x] Screenshots for App Store Connect — captioned 1.0.0 set (Home / History / Parameters × iPhone 6.9″ / iPad 13″): committed raws in `screenshots/raw/en-US/` + the `LinkCleanScreenshots` composer target → App Store-ready PNGs in `fastlane/screenshots/en-US/` (gitignored); pipeline in `docs/release/app-store-metadata.md`. Post-1.0 enrichment: a share-sheet "Clean Link" shot
6. [x] Metadata (App Store Connect) — privacy nutrition label depends on TelemetryDeck (2)
7. [x] Privacy policy — required for App Store submission; draft ready at [ken0nek.com/apps/linkclean/privacy-policy](https://ken0nek.com/apps/linkclean/privacy-policy/), publish before metadata (6)

Added during 1.0.0 (beyond the original priority list):

- [x] **Cleaning transparency on Home** — after a URL is entered or auto-pasted and cleaned, show the user what happened. Asymmetric by design: the *leftover* side is actionable, the *removed* side is read-only.
  - **Leftover (actionable):** surface *every* parameter that survived cleaning as tappable pills — not just reference-catalog trackers (chose max visibility/control on 2026-06-08; arbitrary keys like `test` surface too, via `URLCleaner.leftoverParameterNames`). Tapping one opens a confirm dialog, then adds it to custom tracking parameters (`addCustomParameter`) so it's stripped from then on. The confirm step is the guardrail against globally blocklisting a functional param (`id`, `q`). Raw leftover names are display-only/on-device — never sent; telemetry still uses only `referenceMatches`.
    - Section header "Remaining" + prompt "Tap a parameter to always remove it from your links." Confirm: "Always remove this parameter?" / "“%@” will be removed from your links from now on."
  - **Removed (informational only):** a calm proof-of-work summary — "3 trackers removed," expandable to names. No undo CTA. Rationale: the moment we invite scrutiny on what we removed, we owe the user an undo we're not offering — and transparency builds trust without it (cf. ad blockers' "X trackers blocked").
  - **Restore / per-user allow-list: explicitly out of scope.** Over-cleaning is wrong *for everyone*, so the fix belongs in the default catalog (informed by the catalog-gap / novel-tail telemetry already collected), not a per-user keep-list that adds a confusing second mental model ("strip these… but keep these…"). Revisit only if telemetry shows over-cleaning is both real and uncatchable by catalog curation.
  - **Most detection already exists:** `URLCleaner.cleanResult` returns `removedCount`, `removedKindIDs`, `leftoverCount`, `referenceMatches`. Gap: the result carries counts/kind-IDs (privacy-safe for telemetry), not raw param names — the Home VM can derive names locally from the URL it already holds. Keep raw names out of analytics events.

Done:

- [x] App icon revamp

Out of scope for 1.0.0:

- Localization — identifier-key mechanism was in place; translations shipped in 1.1.0 (ja/de)

Added during 1.0.0 — IAP:

- [x] IAP using **StoreKit 2** — custom paywall + T1–T4 gates + 7-day/1-rule free tier, no grandfathering; plan: [docs/plans/iap-implementation-plan.md](plans/iap-implementation-plan.md)
- [x] IAP strategy (pricing, premium features, free tier limitations) — [docs/strategy/iap-strategy.md](strategy/iap-strategy.md)
- [x] Terms of use — published & live at [ken0nek.com/apps/linkclean/terms-of-use](https://ken0nek.com/apps/linkclean/terms-of-use/)
- [x] App Store Connect setup — regional pricing + paywall screenshot + sandbox test all resolved at ship → [docs/iap/app-store-connect-setup.md](iap/app-store-connect-setup.md)

## 1.1.0 — 📤 Submitted, awaiting App Store review (Jun 16 2026)

Tagged `1.1.0` (`cd0391d`); the full `1.0.0..1.1.0` delta is 47 commits. The store "What's New" (`fastlane/metadata/en-US/release_notes.txt`) is written as a whole-app showcase — the first store note users ever see — not a literal changelog.

User-facing:

- [x] **Clean from anywhere (S1)** — Shortcuts, Siri, Control Center, and a Home Screen widget, on top of the Share Sheet
- [x] **QR codes** — scan a QR to clean the link inside it; generate a QR from a cleaned link (Home "Share as QR" behind an opt-in Setting)
- [x] **Redirect unwrapping (E1)** — follow wrapper links to the real destination before cleaning, with a Home note
- [x] **Fragment cleaning (E2)** — strip trackers + scroll-to-text directives after `#`; default-on "keep scroll-to-text" toggle
- [x] **On-device tracker advisor (ai-A)** — flags the likely trackers among leftover parameters so the user decides
- [x] **Statistics dashboard (V2) + shareable privacy card (V3)** — cumulative impact + a privacy card to share
- [x] **Copy as you want** — plain / Markdown / custom templates + in-extension format picker; custom formats now sold on the paywall
- [x] **Localization** — Japanese + German, plus a HIG/copywriting casing pass across English
- [x] **Bigger / regrouped tracker catalog** — more params stripped; categories regrouped (pixels→ads, HubSpot→analytics, common→referral)

Internal:

- [x] Architecture proposals 1–13 — `CleanOutcome`/`CleanSession`, `AppDependencies` composition root, `ActionPipeline` + strategies, `HistoryStore`, `EntitlementsProviding`, ARCHITECTURE.md rewrite
- [x] LinkCleanKit split into 4 layers (Core / Data / Analytics / ExtensionUI), dependency direction compiler-enforced
- [x] Two-speed test split (macOS fast lane + `LinkCleanTestSupport`)
- [x] Lifetime stat counters (V1) — silent App Group aggregates feeding the V2 dashboard
- [x] Analytics instrumentation — `Stats.*`, paywall conversion sliced by the gate that raised it, QR export tracking, surface-mix; catalog-gap loop fed from every clean surface

## 1.2.0 — 🔜 Backlog (planned, did not make 1.1.0)

- [ ] **ai-C smart titles** — on-device title generation for cleaned links; plan: [plans/001-ai-c-smart-titles.md](../plans/001-ai-c-smart-titles.md) (in-app v1; action-extension use deferred)
- [ ] **E4 short-link expansion** — expand t.co / bit.ly and other shorteners (networked; deliberately excluded from the offline E1 unwrapper); plan: [plans/002-e4-short-link-expansion.md](../plans/002-e4-short-link-expansion.md)
- [ ] **Buy the `linkclean.app` domain + landing page** — not an app-binary item, so it never blocked 1.0/1.1. A dedicated `.app` domain (cf. `whyzard.app`) would give a marketing/landing front door and cleaner support + universal-link URLs, at the cost of registration + mandatory HTTPS. App Store metadata URLs are editable post-launch (today support → `github.com/ken0nek`, privacy → `ken0nek.com/apps/linkclean`), so this can wait. Landing-first build plan: [docs/strategy/monorepo-and-landing.md](strategy/monorepo-and-landing.md). If bought, revisit the support/marketing/privacy URLs.
