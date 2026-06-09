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
/// Privacy (`docs/plans/analytics.md` §3): cases carry only enums, bucketed
/// counts, booleans, and built-in (never user-authored) parameter names —
/// either default-catalog names or names from the bundled reference catalog,
/// both finite and public (`docs/plans/parameter-telemetry.md`). No URLs, hosts,
/// query strings, search text, page titles, or custom-parameter names ever reach
/// this type.
public nonisolated enum AnalyticsEvent: Equatable {

    // MARK: Home (§6)

    /// A valid URL produced a cleaned result. Fired once per distinct input.
    /// `leftoverCount`/`referenceMatchCount`/`removedKinds` are the privacy-safe
    /// catalog-gap signals (`parameter-telemetry.md` Tier 0).
    case homeURLCleaned(
        source: CleanSource,
        changed: Bool,
        removedCount: Int,
        leftoverCount: Int,
        referenceMatchCount: Int,
        removedKinds: Set<String>
    )
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

    // MARK: Onboarding (§6)

    case onboardingFlowCompleted
    case onboardingFlowSkipped
    case onboardingExtensionGuideShown(source: GuideSource)

    // MARK: Action extensions (§7)

    case actionCleanSucceeded(
        changed: Bool,
        removedCount: Int,
        leftoverCount: Int,
        referenceMatchCount: Int,
        removedKinds: Set<String>
    )
    case actionCleanFailed(reason: FailureReason)
    case actionMarkdownSucceeded(titleSource: TitleSource, changed: Bool)
    case actionMarkdownFailed(reason: FailureReason)

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
        case .parametersDefaultToggled: "Parameters.Default.toggled"
        case .parametersCustomAdded: "Parameters.Custom.added"
        case .parametersCustomDeleted: "Parameters.Custom.deleted"
        case .parametersCustomShown: "Parameters.Custom.shown"
        case .parametersReferenceObserved: "Parameters.Reference.observed"
        case .onboardingFlowCompleted: "Onboarding.Flow.completed"
        case .onboardingFlowSkipped: "Onboarding.Flow.skipped"
        case .onboardingExtensionGuideShown: "Onboarding.ExtensionGuide.shown"
        case .actionCleanSucceeded: "Action.Clean.succeeded"
        case .actionCleanFailed: "Action.Clean.failed"
        case .actionMarkdownSucceeded: "Action.Markdown.succeeded"
        case .actionMarkdownFailed: "Action.Markdown.failed"
        }
    }

    // MARK: - Parameters

    /// String parameters sent alongside the signal. Numeric values are bucketed
    /// so insights stay aggregatable and no exact per-user values leak (§5).
    public var parameters: [String: String] {
        switch self {
        case let .homeURLCleaned(source, changed, removedCount, leftoverCount, referenceMatchCount, removedKinds):
            return [
                "source": source.rawValue,
                "changed": Self.string(changed),
                "removedCount": Bucket.removedCount(removedCount),
                "leftoverCount": Bucket.leftoverCount(leftoverCount),
                "referenceMatchCount": Bucket.leftoverCount(referenceMatchCount),
                "removedKinds": Self.kinds(removedKinds),
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
        case let .actionCleanSucceeded(changed, removedCount, leftoverCount, referenceMatchCount, removedKinds):
            return [
                "changed": Self.string(changed),
                "removedCount": Bucket.removedCount(removedCount),
                "leftoverCount": Bucket.leftoverCount(leftoverCount),
                "referenceMatchCount": Bucket.leftoverCount(referenceMatchCount),
                "removedKinds": Self.kinds(removedKinds),
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
        case .settingsScreenShown,
             .parametersCustomShown,
             .homeClipboardInvalidPasted,
             .historyEntryDeleted,
             .historyAllCleared,
             .historySearchUsed,
             .onboardingFlowCompleted,
             .onboardingFlowSkipped:
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
