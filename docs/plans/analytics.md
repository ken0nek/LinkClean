# Analytics Plan

Status: Draft
Scope: TelemetryDeck analytics for 1.0.0 (TODO: "Add analytics using TelemetryDeck"), feeding the 1.1.0 IAP strategy (TODO: "IAP using RevenueCat", "IAP strategy")
Targets: `LinkClean` (main app), `LinkCleanAction`, `LinkCleanMarkdownAction`

---

## 1. Goals

Analytics exists to answer two sets of questions. Every event below maps back to one of them; anything that doesn't is not tracked.

### Product strategy questions

- **Activation** — Do users get from install → first clean → first *extension* clean? Where do they drop off? (The action extension requires manual enablement in the share sheet — the riskiest step in the funnel.)
- **Habit surface** — Is the main app or the action extension the primary surface? This decides where to invest UI effort.
- **Feature adoption** — Are custom parameters, history, search, and the Markdown action actually used, or dead weight?
- **Retention** — D1/D7/D30 retention and weekly active usage.

### IAP strategy questions (for 1.1.0)

- **What to gate** — Which features have enough adoption *and* concentration among heavy users to be premium candidates (custom parameters, unlimited history, Markdown action)?
- **Where to cap** — What does the distribution of cleans/user/week look like? A free-tier usage cap only works if there's a clear power-user tail.
- **Pricing model** — Subscription vs. one-time purchase: justified by retention. High long-term retention → subscription is defensible; quick taper → lifetime unlock.
- **Paywall placement** — At which moment (Nth clean, custom parameter add, history limit) is intent highest?

## 2. Tooling

| Phase | Tool | Purpose |
|---|---|---|
| 1.0.0 | [TelemetryDeck](https://telemetrydeck.com) (Swift SDK, SPM) | Privacy-first usage analytics. Anonymized, no IDFA, aligns with LinkClean's privacy positioning. |
| 1.1.0 | [RevenueCat](https://www.revenuecat.com) | IAP infrastructure. Purchase events forwarded server-side into TelemetryDeck (see §9). |

Integration references (read these before implementing §9):

- https://telemetrydeck.com/docs/integrations/revenuecat/
- https://www.revenuecat.com/docs/integrations/third-party-integrations/telemetrydeck

## 3. Privacy principles

LinkClean's entire value proposition is stripping tracking from URLs. The analytics must be visibly consistent with that.

**Never collect:**

- Full URLs, URL paths, query strings, query *values*, or any clipboard content — not even hashed
- Page titles or thumbnails
- Custom parameter *names* (free-text user input; could contain anything) — track counts only
- Search query text — track that search was used, never what was searched

**Safe to collect:**

- Event names, counts, booleans, bucketed numbers
- Names of *built-in* default parameters being toggled (finite, known set — `utm_source`, `fbclid`, …)
- Catalog-gap counts (how many parameters a clean left behind; how many matched the bundled reference list) and which built-in *categories* fired (`utm`, `ads`, …) — see [parameter-telemetry.md](parameter-telemetry.md) Tier 0
- Names from the bundled **reference catalog** of known trackers (`ReferenceParameterCatalog`) — finite and public, the same risk class as built-in default names (Tier 1)
- TelemetryDeck's default parameters (app version, OS, device model, locale, `extensionIdentifier`)

**Collected, with disclosure (added 2026-06-09):**

- The **site domain** (host) of a cleaned link — e.g. `youtube.com` — on `Home.URL.cleaned` and `Action.Clean.succeeded` only. Lowercased with a leading `www.` stripped (`URLCleaner.analyticsDomain`); other subdomains preserved. A deliberate, product-approved exception to the host rule above: it answers *which sites are cleaned most* (site-popularity → per-site-rule prioritization). Only the host — never the path, query keys, or values.
- **Ship gate.** Because this is URL-derived, it is browsing-adjacent data. Before it reaches production it **requires** (a) the App Store privacy **nutrition label** updated to disclose browsing-history-type collection, and (b) a line in the public **privacy policy** stating site domains (never full URLs or values) are collected. "We never see your URLs" still holds; "we never see which sites" does not — keep public wording precise.

**Other commitments:**

- Set a custom `salt` in `TelemetryDeck.Config` so even TelemetryDeck cannot reverse user identifiers.
- DEBUG builds use TelemetryDeck test mode (automatic) so development noise stays out of production insights.
- Update the App Store privacy nutrition label per TelemetryDeck's guidance when the SDK lands.
- Mention analytics in the privacy policy; consider an opt-out toggle in Settings (decide in review — see §11 Open questions).

## 4. Identity & sessions

- **Shared user identifier:** generate a UUID once, store it in App Group `UserDefaults` (`group.com.ken0nek.LinkClean`, alongside the existing `SettingsKeys`), and pass it as `defaultUser` in all three targets. Without this, the app and each extension count as separate users and the activation funnel (§7) is unmeasurable. The SDK hashes it client-side before transmission.
- **Sessions / installs:** the SDK sends `TelemetryDeck.Session.started` and `newInstallDetected` automatically — retention and acquisition need no custom events.
- This same identifier feeds the RevenueCat integration later (§9) — RevenueCat needs the *hashed* TelemetryDeck user ID as a subscriber attribute, so changing the identity scheme after 1.1.0 ships is costly. Get it right in 1.0.0.

## 5. Signal naming convention

Per [TelemetryDeck's naming guidance](https://telemetrydeck.com/docs/articles/signal-type-naming/): dot-separated paths, max 3 levels, `UpperCamelCase` prefix components, `lowerCamelCase` last component, verb in past tense.

```
Feature.Subject.verbPast      e.g.  History.Entry.copied
```

Numeric parameters are sent as bucketed strings (`"0" | "1" | "2" | "3" | "4" | "5+"` for removed-parameter counts; `"0" | "1-9" | "10-49" | "50+"` for history size) so insights stay aggregatable and no exact values leak.

## 6. Event taxonomy — main app

The north-star action is a **clean**: a URL cleaned *and* exported (copied/shared). Cleaning without export is curiosity; export is value delivered.

### Core cleaning (Home)

| Signal | Trigger | Parameters | Answers |
|---|---|---|---|
| `Home.URL.cleaned` | Valid URL produced a cleaned result (once per distinct input) | `source: autoPaste\|manualPaste\|typed`, `changed: true\|false`, `removedCount: <bucket>`, `leftoverCount: <bucket>`, `referenceMatchCount: <bucket>`, `removedKinds: <ids>\|none`, `domain: <host>`, `unwrapped: true\|false` | Volume; how URLs arrive; how often cleaning changes anything; catalog-gap size and which categories fire (`parameter-telemetry.md` Tier 0); which sites are cleaned most (§3); how often inputs are redirect wrappers (E1 offline unwrapping) → whether to expand the wrapper catalog |
| `Home.URL.copied` | Copy button tapped | `changed` | Home-flow conversion (cleaned → exported) |
| `Home.Clipboard.invalidPasted` | Auto-paste found non-URL (toast shown) | — | Auto-paste annoyance rate; whether it should stay default-on |

### History

| Signal | Trigger | Parameters | Answers |
|---|---|---|---|
| `History.Screen.shown` | History tab opened | `entryCount: <bucket>` | Is history a real feature or a dumping ground? Size distribution → free-tier history cap |
| `History.Entry.actioned` | Per-entry action used | `action: copy\|share\|markdown\|openInBrowser` | Which export paths matter; Markdown demand outside the extension |
| `History.Entry.deleted` | Swipe/context-menu delete | — | Curation behavior |
| `History.All.cleared` | Clear-all confirmed (Settings or History) | — | Privacy-wipe behavior |
| `History.Search.used` | First search per screen visit | — | Whether search justifies its maintenance cost |

### Statistics (growth-roadmap §5 V2/V3)

| Signal | Trigger | Parameters | Answers |
|---|---|---|---|
| `Stats.Screen.shown` | Statistics dashboard opened (`.onAppear`, not the scenePhase refresh) | `hasData: <bool>` | Is the Settings-reached dashboard discovered? Empty-state share → entry point surfaced too early. Denominator for the share-card funnel |
| `Stats.Card.shared` | Privacy card share initiated (no `ShareLink` completion → fires on tap) | `entryPoint: toolbar\|cta` — keyed `entryPoint`, **never `surface`** (process-default param) | **Adoption of the #1 organic growth loop (roadmap §11).** Which entry point drives shares |

### Settings & parameters

| Signal | Trigger | Parameters | Answers |
|---|---|---|---|
| `Settings.Screen.shown` | Settings screen opened | — | Discovery: do users reach Settings at all — the entry to the customization/premium funnel |
| `Settings.AutoPaste.toggled` | Toggle changed | `enabled` | Default acceptance |
| `Settings.SaveHistory.toggled` | Toggle changed | `enabled` | Privacy-sensitivity of user base; viability of history-based premium features |
| `Parameters.Default.toggled` | Built-in parameter toggled | `parameter: <name>`, `enabled` | Which built-ins users distrust/need; informs default set curation |
| `Parameters.Custom.added` | Custom parameter added | `totalCount: <bucket>` — **never the name** | **Top premium candidate.** Adoption % + depth per user |
| `Parameters.Custom.deleted` | Custom parameter removed | `totalCount: <bucket>` | Churn on the feature |
| `Parameters.Custom.shown` | Custom-parameters screen opened | — | **Discovery vs. value for the top premium candidate.** With `Parameters.Custom.added`, view→add conversion separates "few discover it" from "discoverers don't convert" |
| `Parameters.Reference.observed` | A known-but-not-default tracker survived a clean (one per match) | `parameter: <public reference name>` — from the bundled reference catalog, **never an arbitrary URL key** | **Catalog-gap engine.** Which trackers to promote into the default set (`parameter-telemetry.md` Tier 1) |

### Onboarding (ships in 1.0.0 per TODO)

| Signal | Trigger | Parameters | Answers |
|---|---|---|---|
| `Onboarding.Flow.completed` / `Onboarding.Flow.skipped` | End of onboarding | — | Onboarding effectiveness |
| `Onboarding.ExtensionGuide.shown` | "How to enable the action extension" instructions viewed (onboarding or Settings) | `source: onboarding\|settings` | Reach of the single most important activation step |

## 7. Event taxonomy — action extensions

| Signal | Trigger | Parameters | Answers |
|---|---|---|---|
| `Action.Clean.succeeded` | LinkCleanAction copied a cleaned URL | `changed`, `removedCount: <bucket>`, `leftoverCount: <bucket>`, `referenceMatchCount: <bucket>`, `removedKinds: <ids>\|none`, `domain: <host>`, `unwrapped: true\|false` | Extension volume — the habit metric; plus catalog-gap signals and which sites are cleaned most (§3) on the extension surface (`parameter-telemetry.md` Tier 0); whether share-sheet inputs are redirect wrappers (E1). Per-match `Parameters.Reference.observed` is emitted after this signal (§8 convergence) |
| `Action.Clean.failed` | No URL extractable from host input | `reason: noURL\|invalidInput` | Host-app compatibility gaps (e.g. the known Google Maps issue) |
| `Action.Markdown.succeeded` | Markdown action copied `[title](url)` | `titleSource: javascript\|linkPresentation\|urlOnly`, `changed` | Markdown adoption (premium candidate); title-extraction reliability by path |
| `Action.Markdown.failed` | Extraction failed | `reason` | Reliability |

Notes:

- No separate `invoked` signal — `succeeded + failed = invocations`, and extension runtime is too short to waste a second network send. TelemetryDeck's default [`extensionIdentifier` parameter](https://telemetrydeck.com/docs/ingest/default-parameters/) tags every extension signal automatically, so extension traffic is separable from app traffic without extra work.
- **Key derived metric — surface mix:** `Action.Clean.succeeded` vs `Home.URL.copied`. If extensions dominate, the main app is a configuration shell and IAP gating must live in the extension flow (and the paywall in the app must be reachable from an extension-driven moment, e.g. a post-clean history view).

## 8. How extension tracking works (research findings)

**The TelemetryDeck Swift SDK supports app extensions out of the box.** Findings from the SDK source ([SignalManager.swift](https://github.com/TelemetryDeck/SwiftSDK/blob/main/Sources/TelemetryDeck/Signals/SignalManager.swift)):

1. **Extension detection.** The SDK detects extension contexts (bundle path ending in `.appex`) and avoids `UIApplication.shared` background-task APIs there, backing up its signal cache directly. CocoaPods extension compilation was explicitly fixed in 2.7.2 — extensions are a supported environment.
2. **Send mechanics.** Signals go into an in-memory cache; the SDK fires an immediate send attempt and then retries on a timer with exponential backoff. Unsent signals are persisted to disk and reloaded + sent on the next SDK init *in the same process's container*.
3. **The caveat — short-lived processes.** Our extensions live ~0.75 s (toast → `completeRequest`). A tiny JSON POST usually completes in that window, but there is **no public force-flush API**, so delivery from a single extension run is best-effort. Signals that don't make it are persisted and delivered **on the next invocation of that same extension** ("off-by-one" delivery). Aggregate counts converge; only a user's final-ever extension use can be lost.
4. **Separate caches per target.** App, LinkCleanAction, and LinkCleanMarkdownAction each have their own container and signal cache. Each target initializes the SDK itself (same App ID, same shared `defaultUser` from the App Group — §4).

### Recommended approach (1.0.0): direct SDK in extensions

Initialize TelemetryDeck in the shared `ActionExtensionViewController` base class in LinkCleanKit (both extensions inherit it). Signal **as early as possible** in the processing flow — at clean-success, not at dismissal — to maximize in-process network time.

**Built-in validation:** extensions already write `HistoryEntry` rows to the shared SwiftData store. While `saveHistoryEnabled` is on, history row counts are ground truth for extension usage — compare against received `Action.*` signals to measure real-world delivery loss before adding any complexity.

### Fallback (only if measured loss is high): App Group relay queue

Extensions append minimal event records (name + params + timestamp) to a file/`UserDefaults` queue in the App Group container; the main app drains the queue on launch/foreground and replays through TelemetryDeck. Guaranteed eventual delivery and a single network owner, at the cost of plumbing and a delay until the next app open. **Not planned for 1.0.0** — measure first.

## 9. IAP analytics (1.1.0): StoreKit 2 × TelemetryDeck

> **⚠️ Superseded 2026-06-10.** 1.1 shipped on **StoreKit 2, not RevenueCat** (`../plans/iap-implementation-plan.md`). Consequences for this section: there is **no server-side forwarding** (no server, no RevenueCat) — the purchase funnel is **client-side only**, fired from the custom paywall through the typed `AnalyticsEvent` facade as `Paywall.Screen.shown(trigger)` / `Pro.Purchase.started|completed|failed(trigger)` / `Pro.Purchase.restored` (count-only, no amount; started/completed/failed carry the **same `trigger` gate** as the impression — added 2026-06-15 — so paywall→purchase **conversion is sliceable per gate**, e.g. the formats lock vs the history wall; `restored` stays gate-less, it fires from both the paywall and the Settings row). Client-side revenue analytics was **dropped 2026-06-10** — the app sends no `purchaseCompleted(transaction:)` / transaction to TelemetryDeck. **Revenue / refund / conversion-rate truth lives in App Store Connect (Sales & Trends + App Analytics)**, not RevenueCat. The RevenueCat-integration setup below is retained only as historical context for the original plan.

Server-side purchase truth comes from RevenueCat's integration, which forwards subscription events into TelemetryDeck so revenue appears alongside usage signals — including events that happen while the app isn't running (renewals, cancellations, billing issues).

Setup (from the two integration docs):

1. Both SDKs installed; TelemetryDeck initialized with the shared default user (§4).
2. Set two RevenueCat subscriber attributes:
   - `$telemetryDeckAppId` — the TelemetryDeck App ID
   - `$telemetryDeckUserId` — the **hashed** TelemetryDeck user identifier (retrieve from the TD SDK; re-set whenever the TD user identifier changes)
3. Enable TelemetryDeck under RevenueCat dashboard → Integrations and choose event names.

Events RevenueCat forwards: initial purchases, trials/conversions, renewals, cancellations, transfers, revenue (incl. refunds as negative revenue), and optionally `expiration_event`, `billing_issue_event`, `product_change_event`, `uncancellation_event`, `subscription_paused_event`, `non_subscription_purchase_event`. Sandbox events are flagged.

Sources:

- https://telemetrydeck.com/docs/integrations/revenuecat/
- https://www.revenuecat.com/docs/integrations/third-party-integrations/telemetrydeck

Client-side funnel events (thin layer on top of server truth):

| Signal | Trigger | Parameters |
|---|---|---|
| `Paywall.screen.shown` | Paywall presented | `trigger: <placement id>` (e.g. `customParamAdd`, `historyCap`, `nthClean`) |
| `Paywall.screen.dismissed` | Closed without purchase | `trigger` |
| `Paywall.Purchase.started` | Purchase button tapped | `trigger`, `product` |

Completion/failure/restore arrive server-side via RevenueCat; client events exist only to compute view→start conversion per placement.

## 10. Metrics → decisions

| Decision (1.1.0) | Metric | Source signals |
|---|---|---|
| Gate custom parameters? | Adoption % of WAU; depth (`totalCount` buckets); overlap with heavy cleaners | `Parameters.Custom.added` |
| Gate / cap history? | History size distribution; entry-action rate; % with history disabled | `History.Screen.shown`, `History.Entry.actioned`, `Settings.SaveHistory.toggled` |
| Gate Markdown? | Markdown share of extension volume + in-app markdown copies | `Action.Markdown.succeeded`, `History.Entry.actioned(action=markdown)` |
| Free-tier clean cap (and its value N)? | Cleans/user/week distribution — need a distinct power-user tail | `Home.URL.copied` + `Action.*.succeeded` |
| Subscription vs one-time | D7/D30 retention curve shape | Automatic session signals |
| Paywall placement | Conversion per `trigger` once live; pre-launch: which high-intent moments are frequent | `Paywall.*`, §6–7 volumes |
| Onboarding investment | Install → first extension clean rate, and time-to-first | `newInstallDetected` → `Action.Clean.succeeded` |

## 11. Implementation plan

### Phase 1 — Infrastructure (1.0.0)

1. **[user handoff]** Create a TelemetryDeck account + App ID for LinkClean.
2. Add `TelemetryDeck/SwiftSDK` (SPM, up-to-next-major from 2.x) as a dependency of **LinkCleanKit** — one dependency declaration in `Package.swift` serves all three targets. (`TelemetryDeck.signal` is thread-safe; no conflict with the kit's `defaultIsolation(MainActor.self)`.)
3. Create `AnalyticsService` protocol + `TelemetryDeckAnalytics` implementation in `LinkCleanKit/Sources/LinkCleanKit/` — typed signal API so call sites can't invent names; salt + shared `defaultUser` (App Group UUID, §4) configured here. Test target gets a spy implementation.
4. Initialize in `LinkCleanApp.init()` (per TD docs: app `init`, not `onAppear`) and in the `ActionExtensionViewController` base class.

### Phase 2 — Instrumentation (1.0.0)

5. Inject `AnalyticsService` into ViewModels (per `ARCHITECTURE.md` — Views never call services directly); emit §6 events from ViewModel methods. Settings toggles currently bound directly in views route through their ViewModel.
6. Extension events (§7) from the shared base class / kit processing path.
7. Verify in TelemetryDeck dashboard (DEBUG = test mode); confirm `extensionIdentifier` separates surfaces; spot-check extension delivery against history row counts (§8).

### Phase 3 — IAP (1.1.0)

8. RevenueCat SDK, subscriber attributes (`$telemetryDeckAppId`, `$telemetryDeckUserId`), dashboard integration (§9), paywall events.

### Open questions

- Offer an analytics opt-out toggle in Settings? (Not legally required for anonymized TD data in most jurisdictions, but on-brand for a privacy product.)
- `Parameters.Default.toggled` sends built-in parameter names — confirm comfort with that granularity vs. category-level only.
- Should `Home.URL.cleaned` debounce window be per-input-change or per-session? Decide during implementation; document in the service.

## 12. References

- TelemetryDeck × RevenueCat (TelemetryDeck side): https://telemetrydeck.com/docs/integrations/revenuecat/
- RevenueCat × TelemetryDeck (RevenueCat side): https://www.revenuecat.com/docs/integrations/third-party-integrations/telemetrydeck
- TelemetryDeck Swift SDK: https://github.com/TelemetryDeck/SwiftSDK
- Swift client setup: https://telemetrydeck.com/docs/articles/telemetry-client/
- Signal naming: https://telemetrydeck.com/docs/articles/signal-type-naming/
- Default parameters (incl. `extensionIdentifier`): https://telemetrydeck.com/docs/ingest/default-parameters/
- SDK signal cache / extension handling: https://github.com/TelemetryDeck/SwiftSDK/blob/main/Sources/TelemetryDeck/Signals/SignalManager.swift
