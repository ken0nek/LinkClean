//
//  AnalyticsEvent.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 6/8/26.
//

import Foundation

/// The complete LinkClean analytics taxonomy. Every signal the app or an action
/// extension can emit is a case here, so call sites cannot invent names or
/// parameter keys. Signal names follow TelemetryDeck's convention
/// (`Feature.Subject.verbPast`, ≤ 3 levels). See `docs/plans/analytics.md` §5–7.
///
/// Privacy (`docs/plans/analytics.md` §3): cases carry enums, bucketed counts,
/// booleans, built-in (never user-authored) parameter names — either
/// default-catalog names or names from the bundled reference catalog, both finite
/// and public (`docs/plans/parameter-telemetry.md`) — and, by explicit product
/// decision (§3, 2026-06-09), the **site domain** (host) of a cleaned link, on
/// the two clean events only. Still never sent: full URLs, paths, query strings
/// or values, search text, page titles, or custom-parameter names.
public enum AnalyticsEvent: Equatable {

    // MARK: Home (§6)

    /// A valid URL produced a cleaned result. Fired once per distinct input.
    /// Carries the clean's ``CleanOutcome/Telemetry`` — the analytics-safe view
    /// (catalog-gap signals `parameter-telemetry.md` Tier 0, plus the link's
    /// host for site-popularity analytics, the one URL-derived value sent,
    /// `analytics.md` §3). The compiler guarantees a ``CleanOutcome/Display``
    /// name can never be routed here.
    case homeURLCleaned(source: CleanSource, telemetry: CleanOutcome.Telemetry)
    /// The cleaned URL was copied from Home — the in-app north-star export.
    /// Deduped per distinct cleaned output, so this counts *distinct exports*,
    /// not raw tap volume (contrast ``historyEntryActioned``, which fires per tap).
    case homeURLCopied(changed: Bool)
    /// The cleaned URL was shared from Home via the system share sheet — the
    /// other half of the in-app export north-star (paired with ``homeURLCopied``,
    /// and deduped per distinct cleaned output the same way).
    case homeURLShared(changed: Bool)
    /// Auto-paste found a non-URL on the clipboard (annoyance-rate signal).
    case homeClipboardInvalidPasted

    // MARK: History (§6)

    case historyScreenShown(entryCount: Int)
    case historyEntryActioned(EntryAction)
    case historyEntryDeleted
    case historyAllCleared
    /// First search performed during a single History visit.
    case historySearchUsed

    // MARK: Statistics (growth-roadmap §5 V2/V3)

    /// The Statistics dashboard appeared — discovery of the (Settings-reached)
    /// privacy-impact screen, and the denominator for the share-card funnel.
    /// `hasData` separates arrivals at a populated dashboard from the empty state
    /// (a high empty-state share means the entry point surfaces too early).
    case statsScreenShown(hasData: Bool)
    /// The shareable privacy card was shared (growth-roadmap §5 V3) — adoption of
    /// the highest-leverage organic growth loop (roadmap §11). `entryPoint`
    /// distinguishes the toolbar icon from the foot-of-screen CTA, to see which
    /// drives shares. Recorded at share *initiation* (`ShareLink` has no
    /// completion callback), like ``homeURLShared``.
    case statsCardShared(entryPoint: CardShareEntryPoint)

    // MARK: Settings & parameters (§6)

    /// The Settings screen appeared — top of the customization/discovery funnel.
    case settingsScreenShown
    case settingsAutoPasteToggled(enabled: Bool)
    case settingsSaveHistoryToggled(enabled: Bool)
    /// The scroll-to-text fragment (`:~:`) removal setting was toggled — tells us
    /// whether the default-on fragment cleaning is wanted (§6).
    case settingsTextFragmentsToggled(enabled: Bool)
    /// The "Share as QR Code" Home-button setting was toggled — tells us whether
    /// the default-off QR button is wanted, and how many users opt in (§6).
    case settingsQRButtonToggled(enabled: Bool)
    /// The short-link expansion setting was toggled — the app's *only* network
    /// egress, so its opt-in rate is the signal for whether the default-off,
    /// privacy-first stance matches demand (§6). Free for every tier; no paywall.
    case settingsExpandShortLinksToggled(enabled: Bool)
    /// A built-in default parameter was toggled. Its name comes from a finite,
    /// known set, so it is safe to send (§3).
    case parametersDefaultToggled(parameter: String, enabled: Bool)
    /// A custom parameter was added. Only the resulting total (bucketed) is
    /// sent — never the parameter name (free-text user input, §3).
    case parametersCustomAdded(totalCount: Int)
    case parametersCustomDeleted(totalCount: Int)
    /// The custom-parameters screen appeared. Paired with ``parametersCustomAdded``
    /// it separates discovery from value for the top premium candidate (§6): a low
    /// add-rate alongside a healthy view-rate is a value problem, not a discovery one.
    case parametersCustomShown
    /// A known tracking parameter that is *not* in the default catalog survived
    /// a clean — a catalog-gap signal (`parameter-telemetry.md` Tier 1). The
    /// name comes from the bundled ``ReferenceParameterCatalog`` (finite, public
    /// set), so it is safe to send — never a user-authored or arbitrary URL key.
    case parametersReferenceObserved(parameter: String)
    /// A leftover pill was stripped from the current link only (one-time;
    /// nothing persisted). Parameterless: the leftover name is a raw URL key
    /// (§3). Pairs with ``parametersCustomAdded`` — the "always" path — to show
    /// which removal the pill flow actually satisfies.
    case parametersLeftoverRemovedOnce
    /// The unknown-parameter advisor surfaced a leftover it judged a likely
    /// tracker (at most one per clean). ``AdvisorTier`` says which stage produced
    /// it — deterministic reference/heuristic, or the on-device model. Never the
    /// parameter name (a raw URL key, §3) — only the finite tier.
    case parametersAdvisorSuggested(tier: AdvisorTier)
    /// The user accepted an advisor suggestion (tapped Always Remove). Fires on
    /// the intent, whether or not the add is then gated — the funnel's accept
    /// signal. Pairs with ``paywallShown`` (trigger ``PaywallTrigger/advisorAccept``)
    /// for gated free users and ``parametersCustomAdded`` when it lands.
    case parametersAdvisorAccepted(tier: AdvisorTier)
    /// The user dismissed an advisor suggestion ("Not now"). The dismiss-vs-accept
    /// split, sliced by tier, is the advisor's value read (ai-features §9-A).
    case parametersAdvisorDismissed(tier: AdvisorTier)

    // MARK: Onboarding (§6)

    case onboardingFlowCompleted
    case onboardingFlowSkipped
    case onboardingExtensionGuideShown(source: GuideSource)

    // MARK: Action extensions (§7)

    /// A share-sheet clean produced output. Carries the same
    /// ``CleanOutcome/Telemetry`` as ``homeURLCleaned`` (catalog-gap params plus
    /// the `domain` host signal, §3).
    case actionCleanSucceeded(telemetry: CleanOutcome.Telemetry)
    case actionCleanFailed(reason: FailureReason)
    /// The "Copy as you want" action copied a rendered link format (`copy-as-you-want`).
    /// `preset` separates a shipped preset from a user-authored custom template —
    /// the customization-adoption read — and `changed` whether cleaning altered the
    /// URL (as on the other clean events). Never the template's text or name (a
    /// custom name is user-authored, §3): only the finite preset/custom bit.
    case actionFormatSucceeded(preset: Bool, changed: Bool)
    case actionFormatFailed(reason: FailureReason)

    // MARK: App Intents (clean-from-anywhere surfaces — growth-roadmap §4 S1)

    /// An App Intent produced a cleaned link — the Shortcuts / Siri / Spotlight /
    /// Action-button / Control Center / widget surfaces. Carries the same
    /// analytics-safe ``CleanOutcome/Telemetry`` as ``homeURLCleaned`` /
    /// ``actionCleanSucceeded`` (catalog-gap params + the `domain` host signal,
    /// §3), plus which ``IntentSurface`` ran it — the surface-mix read (kpis §6)
    /// for the 1.1 distribution goal.
    case intentCleanSucceeded(surface: IntentSurface, telemetry: CleanOutcome.Telemetry)
    /// An App Intent ran but produced no cleaned link: the clipboard surface tapped
    /// with nothing cleanable (the Control Center / widget annoyance read), or a
    /// Shortcuts input that wasn't a web link. ``IntentSurface`` says which surface,
    /// ``FailureReason`` why (`noURL` = nothing there, `invalidInput` = present but
    /// not a cleanable web link). The failure half of the surface-mix read — without
    /// it a control / widget tap that does nothing is invisible, over-counting the
    /// surfaces' value through ``intentCleanSucceeded`` alone.
    case intentCleanFailed(surface: IntentSurface, reason: FailureReason)

    // MARK: QR (scan & generate — the QR surface)

    /// A QR code was scanned (camera or a picked image) and its link cleaned — the
    /// QR surface's realized clean. Carries the same analytics-safe
    /// ``CleanOutcome/Telemetry`` as the other clean surfaces (catalog-gap params +
    /// the `domain` host signal, §3); History + Stats are recorded at this point,
    /// as with the App Intents.
    case qrScanSucceeded(telemetry: CleanOutcome.Telemetry)
    /// A scan produced no cleanable link: a QR with no web URL (`noLink`) or a
    /// picked image with no readable QR (`unreadable`) — the QR annoyance-rate read.
    case qrScanFailed(reason: QRFailureReason)
    /// A QR image was generated from a cleaned link and shared. `changed` mirrors
    /// the other export events (whether cleaning altered the URL). Recorded at share
    /// initiation (`ShareLink` has no completion callback), like ``homeURLShared``.
    case qrCodeGenerated(changed: Bool)
    /// The user exported a scanned-and-cleaned link from the QR result sheet
    /// (Copy / Share / Open) — the QR surface's realized export. Without it the
    /// scan's downstream value is invisible while ``qrScanSucceeded`` over-counts
    /// intent; the QR analogue of ``historyEntryActioned`` / ``homeURLCopied``.
    case qrResultActioned(QRResultAction)

    // MARK: Review (§6)

    /// The in-app star prompt (`ReviewGateSheet`) appeared.
    case reviewPromptShown
    /// The user picked a rating. Only the coarse high/low **bucket** is sent,
    /// never the exact star count (§3): ≥ 4 → ``ReviewBucket/high`` (routed to
    /// Apple's system prompt), ≤ 3 → ``ReviewBucket/low`` (thanked, no public
    /// rating).
    case reviewStarsSelected(bucket: ReviewBucket)
    /// A high rating invoked Apple's `requestReview()` system prompt.
    case reviewSystemPromptRequested
    /// The user dismissed the star prompt with "Not now".
    case reviewPromptDismissed

    // MARK: Monetization (§9)

    /// The paywall sheet appeared, tagged with the gate that raised it.
    case paywallShown(trigger: PaywallTrigger)
    /// A purchase was initiated from the paywall, tagged with the gate that raised
    /// it — the same `trigger` as ``paywallShown``, so paywall→purchase conversion
    /// can be sliced per gate (which placement actually sells).
    case purchaseStarted(trigger: PaywallTrigger)
    /// A purchase completed synchronously from the paywall (`purchase()` →
    /// `.completed`); pairs with ``paywallShown`` for the paywall→purchase funnel,
    /// sliced by the `trigger` gate. An Ask-to-Buy/SCA approval arrives later via
    /// `Transaction.updates` and is deliberately not counted here — re-emitting from
    /// that loop would double-fire on cross-device/reinstall syncs. Real units sold:
    /// App Store Connect.
    case purchaseCompleted(trigger: PaywallTrigger)
    /// A purchase attempt produced no entitlement (cancelled / pending / error),
    /// tagged with the gate that raised the paywall.
    case purchaseFailed(reason: PurchaseFailureReason, trigger: PaywallTrigger)
    /// A Restore Purchases attempt finished; `restored` is whether it yielded Pro.
    case purchaseRestored(restored: Bool)

    // MARK: - Parameter value types

    /// How the URL reached the Home input.
    public enum CleanSource: String {
        case autoPaste, manualPaste, typed
    }

    /// Which History export path a user took.
    public enum EntryAction: String {
        case copy, share, markdown, openInBrowser
    }

    /// Where the extension guide was shown from.
    public enum GuideSource: String {
        case onboarding, settings
    }

    /// Why an extension run produced no output.
    public enum FailureReason: String {
        case noURL, invalidInput
    }

    /// Why a QR scan produced no cleanable link. A fixed enum, never a URL or the
    /// decoded payload (§3).
    public enum QRFailureReason: String {
        case noLink      // a QR decoded, but it held no web link
        case unreadable  // no QR code was found in the picked image
    }

    /// Which export path the user took from the QR scan-result sheet. Mirrors
    /// ``EntryAction`` but QR-specific — the result sheet offers Copy / Share /
    /// Open, never Markdown.
    public enum QRResultAction: String {
        case copy, share, open
    }

    /// Which App Intents surface ran a clean — the surface-mix slice (kpis §6). A
    /// fixed, low-cardinality enum, never a URL or parameter name. The Control
    /// Center control and the widget button both run the *clipboard* intent, so
    /// they report ``clipboard``; splitting them apart would need a per-surface
    /// intent parameter (which would clutter the Shortcuts editor), deferred until
    /// the data shows it's worth it.
    public enum IntentSurface: String {
        case shortcut    // CleanLinkIntent — Shortcuts / Siri / Spotlight / Action button
        case clipboard   // CleanClipboardIntent — incl. the Control Center control + widget
    }

    /// Which affordance shared the privacy card (growth-roadmap §5 V3) — both run
    /// the same share, so this only tells which entry point users reach for. Sent
    /// under the `entryPoint` key, never `surface` (that key is the process-level
    /// default parameter).
    public enum CardShareEntryPoint: String {
        case toolbar     // the navigation-bar share icon
        case cta         // the prominent foot-of-dashboard "Share your privacy card" button
    }

    /// Which stage of the unknown-parameter advisor produced a suggestion — the
    /// heuristic-vs-model read (ai-features §9-A). Low-cardinality and name-free:
    /// ``reference`` and ``heuristic`` run on every device, ``model`` only on
    /// Apple-Intelligence hardware, so the split also measures how often the
    /// deterministic floor suffices versus needing the model.
    public enum AdvisorTier: String, Sendable {
        case reference   // bundled ReferenceParameterCatalog match (deterministic)
        case heuristic   // TrackerHeuristic name-shape rule (deterministic)
        case model       // on-device Foundation Models verdict
    }

    /// Coarse rating outcome — the only rating detail ever sent (§3), never the
    /// exact star count. ≥ 4 stars is ``high``, ≤ 3 is ``low``.
    public enum ReviewBucket: String {
        case high, low
    }

    /// Why a purchase attempt produced no entitlement.
    public enum PurchaseFailureReason: String {
        case cancelled, pending, storeError
    }

    /// Which gate raised the paywall. A fixed, low-cardinality enum — never a URL
    /// or parameter name (privacy rule, §9). Mirrors the §9 trigger inventory.
    /// `formatPicker` fires from the Copy-formats editor (a Pro preset or a custom
    /// template chosen as the action default — `copy-as-you-want` §4.3);
    /// `onboarding` fires from the first-launch Pro step (the inline paywall shown
    /// after the welcome page); `export`/`sync` stay reserved for later surfaces
    /// and ship unfired.
    public enum PaywallTrigger: String {
        case historyArchive
        case customParamHome
        case customParamSettings
        case settingsRow
        case advisorAccept
        case formatPicker
        case onboarding
        case export
        case sync
    }

    // MARK: - Signal name

    /// The TelemetryDeck signal name. Matches the taxonomy in §6/§7 verbatim.
    public var signalName: String {
        switch self {
        case .homeURLCleaned: "Home.URL.cleaned"
        case .homeURLCopied: "Home.URL.copied"
        case .homeURLShared: "Home.URL.shared"
        case .homeClipboardInvalidPasted: "Home.Clipboard.invalidPasted"
        case .historyScreenShown: "History.Screen.shown"
        case .historyEntryActioned: "History.Entry.actioned"
        case .historyEntryDeleted: "History.Entry.deleted"
        case .historyAllCleared: "History.All.cleared"
        case .historySearchUsed: "History.Search.used"
        case .statsScreenShown: "Stats.Screen.shown"
        case .statsCardShared: "Stats.Card.shared"
        case .settingsScreenShown: "Settings.Screen.shown"
        case .settingsAutoPasteToggled: "Settings.AutoPaste.toggled"
        case .settingsSaveHistoryToggled: "Settings.SaveHistory.toggled"
        case .settingsTextFragmentsToggled: "Settings.TextFragments.toggled"
        case .settingsQRButtonToggled: "Settings.QRButton.toggled"
        case .settingsExpandShortLinksToggled: "Settings.ExpandShortLinks.toggled"
        case .parametersDefaultToggled: "Parameters.Default.toggled"
        case .parametersCustomAdded: "Parameters.Custom.added"
        case .parametersCustomDeleted: "Parameters.Custom.deleted"
        case .parametersCustomShown: "Parameters.Custom.shown"
        case .parametersReferenceObserved: "Parameters.Reference.observed"
        case .parametersLeftoverRemovedOnce: "Parameters.Leftover.removedOnce"
        case .parametersAdvisorSuggested: "Parameters.Advisor.suggested"
        case .parametersAdvisorAccepted: "Parameters.Advisor.accepted"
        case .parametersAdvisorDismissed: "Parameters.Advisor.dismissed"
        case .onboardingFlowCompleted: "Onboarding.Flow.completed"
        case .onboardingFlowSkipped: "Onboarding.Flow.skipped"
        case .onboardingExtensionGuideShown: "Onboarding.ExtensionGuide.shown"
        case .actionCleanSucceeded: "Action.Clean.succeeded"
        case .actionCleanFailed: "Action.Clean.failed"
        case .actionFormatSucceeded: "Action.Format.succeeded"
        case .actionFormatFailed: "Action.Format.failed"
        case .intentCleanSucceeded: "Intent.Clean.succeeded"
        case .intentCleanFailed: "Intent.Clean.failed"
        case .qrScanSucceeded: "QR.Scan.succeeded"
        case .qrScanFailed: "QR.Scan.failed"
        case .qrCodeGenerated: "QR.Code.generated"
        case .qrResultActioned: "QR.Result.actioned"
        case .reviewPromptShown: "Review.Prompt.shown"
        case .reviewStarsSelected: "Review.Stars.selected"
        case .reviewSystemPromptRequested: "Review.SystemPrompt.requested"
        case .reviewPromptDismissed: "Review.Prompt.dismissed"
        case .paywallShown: "Paywall.Screen.shown"
        case .purchaseStarted: "Pro.Purchase.started"
        case .purchaseCompleted: "Pro.Purchase.completed"
        case .purchaseFailed: "Pro.Purchase.failed"
        case .purchaseRestored: "Pro.Purchase.restored"
        }
    }

    // MARK: - Parameters

    /// String parameters sent alongside the signal. Numeric values are bucketed
    /// so insights stay aggregatable and no exact per-user values leak (§5).
    public var parameters: [String: String] {
        switch self {
        case let .homeURLCleaned(source, t):
            return [
                "source": source.rawValue,
                "changed": Self.string(t.changed),
                "removedCount": Bucket.removedCount(t.removedCount),
                "leftoverCount": Bucket.leftoverCount(t.leftoverCount),
                "referenceMatchCount": Bucket.leftoverCount(t.referenceMatches.count),
                "removedKinds": Self.kinds(t.removedKindIDs),
                "domain": t.domain,
                "unwrapped": Self.string(!t.wrappers.isEmpty),
                "expanded": Self.string(t.expanded),
            ]
        case let .homeURLCopied(changed),
             let .homeURLShared(changed):
            return ["changed": Self.string(changed)]
        case let .historyScreenShown(entryCount):
            return ["entryCount": Bucket.historySize(entryCount)]
        case let .statsScreenShown(hasData):
            return ["hasData": Self.string(hasData)]
        case let .statsCardShared(entryPoint):
            // Keyed `entryPoint`, not `surface` — the process-level `surface`
            // default parameter (app/intent) would collide, exactly as the
            // intent-clean event guards against with `intentSurface`.
            return ["entryPoint": entryPoint.rawValue]
        case let .historyEntryActioned(action):
            return ["action": action.rawValue]
        case let .settingsAutoPasteToggled(enabled):
            return ["enabled": Self.string(enabled)]
        case let .settingsSaveHistoryToggled(enabled):
            return ["enabled": Self.string(enabled)]
        case let .settingsTextFragmentsToggled(enabled):
            return ["enabled": Self.string(enabled)]
        case let .settingsQRButtonToggled(enabled):
            return ["enabled": Self.string(enabled)]
        case let .settingsExpandShortLinksToggled(enabled):
            return ["enabled": Self.string(enabled)]
        case let .parametersDefaultToggled(parameter, enabled):
            return ["parameter": parameter, "enabled": Self.string(enabled)]
        case let .parametersCustomAdded(totalCount):
            return ["totalCount": Bucket.count(totalCount)]
        case let .parametersCustomDeleted(totalCount):
            return ["totalCount": Bucket.count(totalCount)]
        case let .parametersReferenceObserved(parameter):
            return ["parameter": parameter]
        case let .parametersAdvisorSuggested(tier),
             let .parametersAdvisorAccepted(tier),
             let .parametersAdvisorDismissed(tier):
            return ["tier": tier.rawValue]
        case let .onboardingExtensionGuideShown(source):
            return ["source": source.rawValue]
        case let .actionCleanSucceeded(t):
            return [
                "changed": Self.string(t.changed),
                "removedCount": Bucket.removedCount(t.removedCount),
                "leftoverCount": Bucket.leftoverCount(t.leftoverCount),
                "referenceMatchCount": Bucket.leftoverCount(t.referenceMatches.count),
                "removedKinds": Self.kinds(t.removedKindIDs),
                "domain": t.domain,
                "unwrapped": Self.string(!t.wrappers.isEmpty),
                "expanded": Self.string(t.expanded),
            ]
        case let .actionCleanFailed(reason):
            return ["reason": reason.rawValue]
        case let .actionFormatSucceeded(preset, changed):
            return [
                "preset": Self.string(preset),
                "changed": Self.string(changed),
            ]
        case let .actionFormatFailed(reason):
            return ["reason": reason.rawValue]
        case let .intentCleanSucceeded(surface, t):
            return [
                // Distinct from the process-level `surface` default parameter
                // (`app`/`intent`, set in TelemetryDeckAnalytics.start) so the two
                // never collide on this signal — this carries the *logical* surface
                // (shortcut vs clipboard), that carries the process.
                "intentSurface": surface.rawValue,
                "changed": Self.string(t.changed),
                "removedCount": Bucket.removedCount(t.removedCount),
                "leftoverCount": Bucket.leftoverCount(t.leftoverCount),
                "referenceMatchCount": Bucket.leftoverCount(t.referenceMatches.count),
                "removedKinds": Self.kinds(t.removedKindIDs),
                "domain": t.domain,
                "unwrapped": Self.string(!t.wrappers.isEmpty),
                "expanded": Self.string(t.expanded),
            ]
        case let .intentCleanFailed(surface, reason):
            return ["intentSurface": surface.rawValue, "reason": reason.rawValue]
        case let .qrScanSucceeded(t):
            return [
                "changed": Self.string(t.changed),
                "removedCount": Bucket.removedCount(t.removedCount),
                "leftoverCount": Bucket.leftoverCount(t.leftoverCount),
                "referenceMatchCount": Bucket.leftoverCount(t.referenceMatches.count),
                "removedKinds": Self.kinds(t.removedKindIDs),
                "domain": t.domain,
                "unwrapped": Self.string(!t.wrappers.isEmpty),
                "expanded": Self.string(t.expanded),
            ]
        case let .qrScanFailed(reason):
            return ["reason": reason.rawValue]
        case let .qrCodeGenerated(changed):
            return ["changed": Self.string(changed)]
        case let .qrResultActioned(action):
            return ["action": action.rawValue]
        case let .reviewStarsSelected(bucket):
            return ["bucket": bucket.rawValue]
        case let .paywallShown(trigger),
             let .purchaseStarted(trigger),
             let .purchaseCompleted(trigger):
            return ["trigger": trigger.rawValue]
        case let .purchaseFailed(reason, trigger):
            return ["reason": reason.rawValue, "trigger": trigger.rawValue]
        case let .purchaseRestored(restored):
            return ["restored": Self.string(restored)]
        case .settingsScreenShown,
             .parametersCustomShown,
             .parametersLeftoverRemovedOnce,
             .homeClipboardInvalidPasted,
             .historyEntryDeleted,
             .historyAllCleared,
             .historySearchUsed,
             .onboardingFlowCompleted,
             .onboardingFlowSkipped,
             .reviewPromptShown,
             .reviewSystemPromptRequested,
             .reviewPromptDismissed:
            return [:]
        }
    }

    private static func string(_ value: Bool) -> String {
        value ? "true" : "false"
    }

    /// Sorted, comma-joined catalog kind ids that fired in a clean (e.g.
    /// `"ads,utm"`), or `"none"` when nothing matched the built-in catalog (a
    /// clean that removed only custom parameters, or removed nothing). Each id
    /// is from the finite ``TrackingParameterCatalog`` — safe to send.
    private static func kinds(_ ids: Set<String>) -> String {
        ids.isEmpty ? "none" : ids.sorted().joined(separator: ",")
    }

    // MARK: - Bucketing

    /// Numeric parameters are sent as bucketed strings (§5).
    enum Bucket {
        /// Removed tracking-parameter count: exact 0–4, then `"5+"`.
        static func removedCount(_ value: Int) -> String {
            value >= 5 ? "5+" : String(max(0, value))
        }

        /// Leftover / reference-match count after cleaning — same shape as
        /// `removedCount` (exact 0–4, then `"5+"`). Small by nature; the gap
        /// question is "any, and roughly how many", not the exact tail.
        static func leftoverCount(_ value: Int) -> String {
            removedCount(value)
        }

        /// History size: `"0" | "1-9" | "10-49" | "50+"`.
        static func historySize(_ value: Int) -> String {
            switch value {
            case ..<1: "0"
            case ..<10: "1-9"
            case ..<50: "10-49"
            default: "50+"
            }
        }

        /// Small per-user counts (e.g. custom parameters) — finer low-end
        /// granularity, where the depth-of-adoption questions live (§10).
        static func count(_ value: Int) -> String {
            switch value {
            case ..<1: "0"
            case 1: "1"
            case 2: "2"
            case 3...4: "3-4"
            case 5...9: "5-9"
            default: "10+"
            }
        }
    }
}

extension CleanOutcome.Telemetry {
    /// One ``AnalyticsEvent/parametersReferenceObserved(parameter:)`` per
    /// catalog-gap tracker left behind (Tier 1) — the fan-out every clean surface
    /// emits after its own success signal, so no surface re-derives the loop. Only
    /// public reference-catalog names ride here (finite, never user input; §3).
    public var referenceObservedEvents: [AnalyticsEvent] {
        referenceMatches.map { .parametersReferenceObserved(parameter: $0) }
    }
}

extension AnalyticsEvent.PaywallTrigger: Identifiable {
    /// `.sheet(item:)` (the paywall presentation currency) needs `Identifiable`;
    /// the trigger's `rawValue` is a stable id. Declared here next to the enum so
    /// the app no longer needs a `@retroactive` conformance.
    public var id: String { rawValue }
}
