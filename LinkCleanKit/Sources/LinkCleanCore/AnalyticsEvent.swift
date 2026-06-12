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

    // MARK: Settings & parameters (§6)

    /// The Settings screen appeared — top of the customization/discovery funnel.
    case settingsScreenShown
    case settingsAutoPasteToggled(enabled: Bool)
    case settingsSaveHistoryToggled(enabled: Bool)
    /// The scroll-to-text fragment (`:~:`) removal setting was toggled — tells us
    /// whether the default-on fragment cleaning is wanted (§6).
    case settingsTextFragmentsToggled(enabled: Bool)
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
    case actionMarkdownSucceeded(titleSource: TitleSource, changed: Bool)
    case actionMarkdownFailed(reason: FailureReason)

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
    /// A purchase was initiated from the paywall.
    case purchaseStarted
    /// A purchase completed synchronously from the paywall (`purchase()` →
    /// `.completed`); pairs with ``paywallShown`` for the paywall→purchase funnel.
    /// An Ask-to-Buy/SCA approval arrives later via `Transaction.updates` and is
    /// deliberately not counted here — re-emitting from that loop would double-fire
    /// on cross-device/reinstall syncs. Real units sold: App Store Connect.
    case purchaseCompleted
    /// A purchase attempt produced no entitlement (cancelled / pending / error).
    case purchaseFailed(reason: PurchaseFailureReason)
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

    /// Which path produced the Markdown title.
    public enum TitleSource: String {
        case javascript, linkPresentation, urlOnly
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
    /// or parameter name (privacy rule, §9). Mirrors the §9 trigger inventory;
    /// `advisorAccept`/`formatPicker`/`export`/`sync` are reserved for 1.2+
    /// surfaces and ship unfired.
    public enum PaywallTrigger: String {
        case historyArchive
        case customParamHome
        case customParamSettings
        case settingsRow
        case advisorAccept
        case formatPicker
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
        case .settingsScreenShown: "Settings.Screen.shown"
        case .settingsAutoPasteToggled: "Settings.AutoPaste.toggled"
        case .settingsSaveHistoryToggled: "Settings.SaveHistory.toggled"
        case .settingsTextFragmentsToggled: "Settings.TextFragments.toggled"
        case .parametersDefaultToggled: "Parameters.Default.toggled"
        case .parametersCustomAdded: "Parameters.Custom.added"
        case .parametersCustomDeleted: "Parameters.Custom.deleted"
        case .parametersCustomShown: "Parameters.Custom.shown"
        case .parametersReferenceObserved: "Parameters.Reference.observed"
        case .parametersLeftoverRemovedOnce: "Parameters.Leftover.removedOnce"
        case .onboardingFlowCompleted: "Onboarding.Flow.completed"
        case .onboardingFlowSkipped: "Onboarding.Flow.skipped"
        case .onboardingExtensionGuideShown: "Onboarding.ExtensionGuide.shown"
        case .actionCleanSucceeded: "Action.Clean.succeeded"
        case .actionCleanFailed: "Action.Clean.failed"
        case .actionMarkdownSucceeded: "Action.Markdown.succeeded"
        case .actionMarkdownFailed: "Action.Markdown.failed"
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
            ]
        case let .homeURLCopied(changed),
             let .homeURLShared(changed):
            return ["changed": Self.string(changed)]
        case let .historyScreenShown(entryCount):
            return ["entryCount": Bucket.historySize(entryCount)]
        case let .historyEntryActioned(action):
            return ["action": action.rawValue]
        case let .settingsAutoPasteToggled(enabled):
            return ["enabled": Self.string(enabled)]
        case let .settingsSaveHistoryToggled(enabled):
            return ["enabled": Self.string(enabled)]
        case let .settingsTextFragmentsToggled(enabled):
            return ["enabled": Self.string(enabled)]
        case let .parametersDefaultToggled(parameter, enabled):
            return ["parameter": parameter, "enabled": Self.string(enabled)]
        case let .parametersCustomAdded(totalCount):
            return ["totalCount": Bucket.count(totalCount)]
        case let .parametersCustomDeleted(totalCount):
            return ["totalCount": Bucket.count(totalCount)]
        case let .parametersReferenceObserved(parameter):
            return ["parameter": parameter]
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
            ]
        case let .actionCleanFailed(reason):
            return ["reason": reason.rawValue]
        case let .actionMarkdownSucceeded(titleSource, changed):
            return [
                "titleSource": titleSource.rawValue,
                "changed": Self.string(changed),
            ]
        case let .actionMarkdownFailed(reason):
            return ["reason": reason.rawValue]
        case let .reviewStarsSelected(bucket):
            return ["bucket": bucket.rawValue]
        case let .paywallShown(trigger):
            return ["trigger": trigger.rawValue]
        case let .purchaseFailed(reason):
            return ["reason": reason.rawValue]
        case let .purchaseRestored(restored):
            return ["restored": Self.string(restored)]
        case .purchaseStarted,
             .purchaseCompleted,
             .settingsScreenShown,
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

extension AnalyticsEvent.PaywallTrigger: Identifiable {
    /// `.sheet(item:)` (the paywall presentation currency) needs `Identifiable`;
    /// the trigger's `rawValue` is a stable id. Declared here next to the enum so
    /// the app no longer needs a `@retroactive` conformance.
    public var id: String { rawValue }
}
