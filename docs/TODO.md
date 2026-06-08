# LinkClean TODO

## 1.0.0

In priority order:

1. [x] Fix Google Maps link sharing issue — only unknown-scope item; core share-sheet flow
2. [x] Add analytics using TelemetryDeck — plan: [docs/plans/analytics.md](plans/analytics.md); §6/§7 taxonomy implemented across app + both action extensions (`AnalyticsService`/`AnalyticsEvent` in LinkCleanKit)
3. [x] Initial onboarding — plan: [docs/plans/onboarding.md](plans/onboarding.md); funnel events now wired (`Onboarding.flow.completed`/`skipped`, `Onboarding.ExtensionGuide.shown`)
   - [x] Instruction to add action extension (how to enable it in the share sheet) — interactive `ExtensionGuideView`, shown in onboarding and from Settings
4. [x] Action extension icon asset per extension — needed before share-sheet screenshots
   - [x] LinkCleanAction
   - [x] LinkCleanMarkdownAction
5. [ ] Screenshots for App Store Connect — after UI freeze (3) and icons (4)
6. [ ] Metadata (App Store Connect) — privacy nutrition label depends on TelemetryDeck (2)
7. [ ] Privacy policy — required for App Store submission; draft ready at [ken0nek.com/apps/linkclean/privacy-policy](https://ken0nek.com/apps/linkclean/privacy-policy/), publish before metadata (6)

Feature ideas (not committed — captured for consideration):

- [ ] **Leftover-parameter pills on Home** — after a URL is entered or auto-pasted and cleaned, inspect what query parameters remain. Surface each remaining parameter as a tappable pill below the result, with a prompt inviting the user to strip it. Tapping a pill adds that parameter to custom tracking parameters, so it's removed automatically from then on.
  - Prompt copy (brush-up of "Want to remove parameter?"): "Found leftover parameters — tap to always remove them." Alternatives: "Still in your link. Remove these?" / "These weren't cleaned — strip them too?"
  - Turns a one-off observation into a persistent rule (feeds the existing custom-parameter store), so the catalog grows from real user links.

Done:

- [x] App icon revamp

Out of scope for this version:

- No localization (identifier-key mechanism is in place; translations come later)
- No IAP

## 1.1.0

- [ ] IAP using RevenueCat — plan: [docs/plans/iap-implementation-plan.md](plans/iap-implementation-plan.md)
- [x] IAP strategy (pricing, premium features, free tier limitations) — [docs/strategy/iap-strategy.md](strategy/iap-strategy.md)
- [ ] Terms of use — required once IAP ships (Apple EULA requirement); draft ready at [ken0nek.com/apps/linkclean/terms-of-use](https://ken0nek.com/apps/linkclean/terms-of-use/)
