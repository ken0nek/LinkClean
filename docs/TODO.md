# LinkClean TODO

## 1.0.0

In priority order:

1. [ ] Fix Google Maps link sharing issue — only unknown-scope item; core share-sheet flow
2. [ ] Add analytics using TelemetryDeck — plan: [docs/plans/analytics.md](plans/analytics.md); land before onboarding so the activation funnel ships instrumented from day one
3. [ ] Initial onboarding — build with funnel events inline
   - [ ] Instruction to add action extension (how to enable it in the share sheet) — part of onboarding, also reachable from Settings
4. [ ] Action extension icon asset per extension — needed before share-sheet screenshots
   - [ ] LinkCleanAction
   - [ ] LinkCleanMarkdownAction
5. [ ] Screenshots for App Store Connect — after UI freeze (3) and icons (4)
6. [ ] Metadata (App Store Connect) — privacy nutrition label depends on TelemetryDeck (2)

Done:

- [x] App icon revamp

Out of scope for this version:

- No localization (identifier-key mechanism is in place; translations come later)
- No IAP

## 1.1.0

- [ ] IAP using RevenueCat — plan: [docs/plans/iap-implementation-plan.md](plans/iap-implementation-plan.md)
- [x] IAP strategy (pricing, premium features, free tier limitations) — [docs/strategy/iap-strategy.md](strategy/iap-strategy.md)
