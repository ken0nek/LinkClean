//
//  ActionPipeline.swift
//  LinkCleanExtensionUI
//
//  Created by Ken Tominaga on 6/11/26.
//

import Foundation
import LinkCleanCore
import LinkCleanData
import LinkCleanAnalytics

/// Which toast the host shows. A semantic kind, localized at the UI edge — the
/// pipeline never names a string.
public enum ToastKind: Sendable, Equatable {
    case copied
    case noLinkFound
}

/// Which success/error haptic the host plays.
public enum HapticKind: Sendable, Equatable {
    case success
    case error
}

/// What to put on the system pasteboard: a URL (Clean) or a string (Markdown).
public struct PasteboardPayload: Sendable, Equatable {
    public enum Content: Sendable, Equatable {
        case url(URL)
        case string(String)
    }
    public let content: Content

    public init(_ content: Content) {
        self.content = content
    }
}

/// The web URL an extension extracted, plus any title the host page's JavaScript
/// preprocessing already provided (Markdown only).
public struct ExtractedURL: Sendable, Equatable {
    public let url: URL
    public let jsTitle: String?

    public init(url: URL, jsTitle: String? = nil) {
        self.url = url
        self.jsTitle = jsTitle
    }
}

/// A strategy's surface-specific output: the pasteboard payload plus the success
/// events to emit. Pure values, so a strategy is unit-testable without a view
/// controller or a live pasteboard.
public struct StrategyResult: Sendable {
    public let payload: PasteboardPayload
    public let successEvents: [AnalyticsEvent]

    public init(payload: PasteboardPayload, successEvents: [AnalyticsEvent]) {
        self.payload = payload
        self.successEvents = successEvents
    }
}

/// A user-selectable output option, for strategies that support an in-extension
/// picker (the Copy action's active formats — `copy-as-you-want` v2). `id`
/// identifies the choice back to the strategy; `title` is the already-localized
/// label the host shows.
public struct ActionChoice: Sendable, Identifiable, Equatable {
    public let id: UUID
    public let title: String

    public init(id: UUID, title: String) {
        self.id = id
        self.title = title
    }
}

/// What the host should present after the pipeline runs: the pasteboard payload
/// (`nil` on failure), the toast, and the haptic.
public struct ActionPresentation: Sendable {
    public let payload: PasteboardPayload?
    public let toast: ToastKind
    public let haptic: HapticKind

    public init(payload: PasteboardPayload?, toast: ToastKind, haptic: HapticKind) {
        self.payload = payload
        self.toast = toast
        self.haptic = haptic
    }
}

/// The surface-specific half of an action extension: how to find the URL, what
/// to emit on failure, and how to turn a cleaned outcome into a pasteboard
/// payload + success events. Each extension target is a one-line choice of
/// strategy; a third extension ("Copy as HTML") is a new strategy, not a fourth
/// copy of the shared ritual.
public protocol ActionOutputStrategy: Sendable {
    /// Analytics surface id (per-process SDK init + signal context).
    var surface: String { get }

    /// Acquire the web URL (and, for Markdown, a JS-provided page title) from the
    /// shared extension input. `nil` when nothing usable was shared.
    func extract(from items: [NSExtensionItem]) async -> ExtractedURL?

    /// The event to emit when ``extract(from:)`` finds nothing. `hasAttachments`
    /// distinguishes "host shared nothing" (`noURL`) from "host shared something
    /// we couldn't turn into a web URL" (`invalidInput`).
    func failureEvent(hasAttachments: Bool) -> AnalyticsEvent

    /// Turn a cleaned outcome into the pasteboard payload + success events (the
    /// single / default output — used when there's no picker).
    func result(for outcome: CleanOutcome, extracted: ExtractedURL) async -> StrategyResult

    /// The user-selectable options to offer *before* producing output. Two or more
    /// ⇒ the host shows a picker; fewer ⇒ it uses ``result(for:extracted:)``
    /// directly. Synchronous and URL-independent (the active formats), so the host
    /// can decide picker-vs-silent the instant the clean finishes.
    func choices() -> [ActionChoice]

    /// Produce the result for a chosen option (`choiceID` is an ``ActionChoice/id``).
    func result(for outcome: CleanOutcome, extracted: ExtractedURL, choiceID: UUID) async -> StrategyResult
}

public extension ActionOutputStrategy {
    /// Default: no picker. A strategy with a single output (e.g. ``CleanLinkStrategy``)
    /// inherits this and is never asked to choose.
    func choices() -> [ActionChoice] { [] }

    /// Default: ignore the choice and produce the single output.
    func result(for outcome: CleanOutcome, extracted: ExtractedURL, choiceID: UUID) async -> StrategyResult {
        await result(for: outcome, extracted: extracted)
    }
}

/// The cleaned context carried from ``ActionPipeline/prepare(items:hasAttachments:)``
/// to ``ActionPipeline/complete(_:choiceID:)`` — opaque to the host, which only
/// holds it across a picker interaction and hands it back.
public struct Prepared: Sendable {
    let outcome: CleanOutcome
    let extracted: ExtractedURL
}

/// The result of ``ActionPipeline/prepare(items:hasAttachments:)``: either nothing
/// usable was shared (present the failure directly), or a cleaned context plus the
/// picker `choices` (two or more ⇒ the host shows a menu before completing).
public enum PreparedAction: Sendable {
    case failure(ActionPresentation)
    case ready(Prepared, choices: [ActionChoice])
}

/// The shared *sequence* every action extension runs, made the reusable artifact
/// (inheritance could share the steps but not their order, so each subclass used
/// to restate it). Parameterized by an ``ActionOutputStrategy``; UIKit-free, so
/// the host renders the returned ``ActionPresentation`` and the flow is testable
/// as values.
public struct ActionPipeline {
    private let strategy: any ActionOutputStrategy
    private let cleaning: CleaningService
    private let settings: SettingsStore
    private let analytics: AnalyticsService
    private let stats: StatsStore

    public init(
        strategy: any ActionOutputStrategy,
        cleaning: CleaningService = DefaultCleaningService(),
        settings: SettingsStore = SettingsStore(),
        analytics: AnalyticsService = TelemetryDeckAnalytics(),
        stats: StatsStore = StatsStore()
    ) {
        self.strategy = strategy
        self.cleaning = cleaning
        self.settings = settings
        self.analytics = analytics
        self.stats = stats
    }

    /// The one-shot path: extract → clean → produce the single output. Used by the
    /// Clean action and by the Copy action when at most one format is active.
    public func run(items: [NSExtensionItem], hasAttachments: Bool) async -> ActionPresentation {
        switch await prepare(items: items, hasAttachments: hasAttachments) {
        case .failure(let presentation):
            return presentation
        case .ready(let prepared, _):
            return await complete(prepared, choiceID: nil)
        }
    }

    /// Phase 1 (extract + clean), returning the cleaned context plus the picker
    /// choices to offer — or a failure presentation when no URL was shared. Records
    /// nothing: a clean the user then cancels in the picker must leave no trace.
    public func prepare(items: [NSExtensionItem], hasAttachments: Bool) async -> PreparedAction {
        guard let extracted = await strategy.extract(from: items) else {
            // Attachments present but unparseable = host-compat gap; nothing
            // shared at all = noURL.
            analytics.capture(strategy.failureEvent(hasAttachments: hasAttachments))
            return .failure(ActionPresentation(payload: nil, toast: .noLinkFound, haptic: .error))
        }

        // A validated web URL cleans; a non-web JS URL the service declines falls
        // back to an unchanged outcome so output is still produced.
        let outcome = (try? await cleaning.clean(extracted.url.absoluteString))
            ?? URLCleaner.outcome(for: extracted.url.absoluteString, removing: [])

        return .ready(Prepared(outcome: outcome, extracted: extracted), choices: strategy.choices())
    }

    /// Phase 2: render `choiceID` (or the single output when `nil`), write the
    /// pasteboard payload, and record the success signals, stats, and History. This
    /// is the only place a copy is counted, so it fires once — after the user has
    /// committed to a format (picker tap) or immediately (single active).
    public func complete(_ prepared: Prepared, choiceID: UUID?) async -> ActionPresentation {
        let result: StrategyResult
        if let choiceID {
            result = await strategy.result(for: prepared.outcome, extracted: prepared.extracted, choiceID: choiceID)
        } else {
            result = await strategy.result(for: prepared.outcome, extracted: prepared.extracted)
        }

        // Emit at clean-success (not dismissal) to maximize in-process network
        // time in the short-lived extension (analytics §8).
        for event in result.successEvents {
            analytics.capture(event)
        }
        stats.record(prepared.outcome)
        saveHistory(original: prepared.extracted.url.absoluteString, outcome: prepared.outcome)
        recordSuccessfulRun()
        return ActionPresentation(payload: result.payload, toast: .copied, haptic: .success)
    }

    // MARK: - History + onboarding success signal

    private func saveHistory(original: String, outcome: CleanOutcome) {
        // The onboarding "Try it" run is a practice clean, not a real one — never
        // persist it. `recordSuccessfulRun` still fires so the guide detects it.
        guard !OnboardingDemo.matches(urlString: original) else {
            Log.action.debug("saveHistory: skipping onboarding demo link")
            return
        }
        // Store the cleaned-from *destination* (`outcome.input`) and the arrival host
        // separately, so the before→after diffs the destination's own params and the
        // "Expanded from …" banner still renders for extension cleans.
        if settings.saveHistoryEnabled, let container = HistoryContainer.makeShared() {
            do {
                try HistoryRecorder.save(
                    input: outcome.input,
                    output: outcome.cleaned,
                    arrivedFromHost: outcome.arrivedFromHost,
                    in: container
                )
            } catch {
                Log.action.debug("saveHistory failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Records a successful run so the app's onboarding/guide can auto-detect it
    /// on scene activation. Independent of `saveHistoryEnabled`.
    private func recordSuccessfulRun() {
        settings.lastActionExtensionRunAt = .now
    }
}
