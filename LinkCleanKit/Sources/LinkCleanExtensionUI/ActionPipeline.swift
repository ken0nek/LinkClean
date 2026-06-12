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

    /// Turn a cleaned outcome into the pasteboard payload + success events.
    func result(for outcome: CleanOutcome, extracted: ExtractedURL) async -> StrategyResult
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

    public func run(items: [NSExtensionItem], hasAttachments: Bool) async -> ActionPresentation {
        guard let extracted = await strategy.extract(from: items) else {
            // Attachments present but unparseable = host-compat gap; nothing
            // shared at all = noURL.
            analytics.capture(strategy.failureEvent(hasAttachments: hasAttachments))
            return ActionPresentation(payload: nil, toast: .noLinkFound, haptic: .error)
        }

        // A validated web URL cleans; a non-web JS URL the service declines falls
        // back to an unchanged outcome so Markdown is still produced.
        let outcome = (try? await cleaning.clean(extracted.url.absoluteString))
            ?? URLCleaner.outcome(for: extracted.url.absoluteString, removing: [])

        let result = await strategy.result(for: outcome, extracted: extracted)

        // Emit at clean-success (not dismissal) to maximize in-process network
        // time in the short-lived extension (analytics §8).
        for event in result.successEvents {
            analytics.capture(event)
        }
        stats.record(outcome.telemetry)
        saveHistory(input: extracted.url.absoluteString, output: outcome.cleaned)
        recordSuccessfulRun()
        return ActionPresentation(payload: result.payload, toast: .copied, haptic: .success)
    }

    // MARK: - History + onboarding success signal

    private func saveHistory(input: String, output: String) {
        // The onboarding "Try it" run is a practice clean, not a real one — never
        // persist it. `recordSuccessfulRun` still fires so the guide detects it.
        guard !OnboardingDemo.matches(urlString: input) else {
            Log.action.debug("saveHistory: skipping onboarding demo link")
            return
        }
        if settings.saveHistoryEnabled, let container = HistoryContainer.makeShared() {
            do {
                try HistoryRecorder.save(input: input, output: output, in: container)
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
