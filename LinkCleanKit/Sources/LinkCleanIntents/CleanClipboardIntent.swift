//
//  CleanClipboardIntent.swift
//  LinkCleanIntents
//
//  Created by Ken Tominaga on 6/12/26.
//

#if canImport(UIKit)
import AppIntents
import UIKit
import LinkCleanCore
import LinkCleanData
import LinkCleanAnalytics

/// Cleans the link currently on the clipboard, in place — the Control Center /
/// widget / "clean my clipboard" Siri surface (S1), and the killer flow: copy a
/// link anywhere, tap the control, the cleaned link replaces it.
///
/// Privacy: ``UIPasteboard`` reads raise the system paste banner. We call
/// `detectPatterns(for:)` first — which inspects the clipboard *without* reading
/// its value or prompting — and only read `string` when a probable web URL is
/// actually present, so an empty/irrelevant clipboard never triggers a banner.
public struct CleanClipboardIntent: AppIntent {
    public static let title: LocalizedStringResource = .init("intents.cleanClipboard.title", defaultValue: "Clean Clipboard")
    public static let description = IntentDescription(
        "Removes tracking parameters from the link on your clipboard."
    )

    public static let openAppWhenRun = false

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let pasteboard = UIPasteboard.general
        let settings = SettingsStore()

        // Check for a link without reading the value (no paste banner) so a
        // clipboard with nothing to clean stays silent. `detectPatterns` bridges
        // via a completion handler, not async/await, so wrap it.
        let patterns: Set<UIPasteboard.DetectionPattern>? = try? await withCheckedThrowingContinuation { continuation in
            pasteboard.detectPatterns(for: [.probableWebURL]) { result in
                continuation.resume(with: result)
            }
        }
        guard patterns?.contains(.probableWebURL) == true, let raw = pasteboard.string else {
            return .result(dialog: "There's no link on your clipboard to clean.")
        }

        let cleaning = DefaultCleaningService(settings: settings)
        guard let outcome = try await cleaning.clean(raw) else {
            return .result(dialog: "There's no link on your clipboard to clean.")
        }

        // Only rewrite the clipboard when cleaning changed something — re-setting an
        // already-clean link would bump the pasteboard's change count and re-trigger
        // "pasted from" / Universal Clipboard for no reason.
        if outcome.telemetry.changed {
            pasteboard.string = outcome.cleaned
        }
        // Emit the signal before the slower history write (analytics §8): a control/
        // widget tap runs in a short-lived process, so fire the deliverable + signal
        // before awaiting persistence.
        TelemetryDeckAnalytics.startIfNeeded(surface: "intent")
        TelemetryDeckAnalytics().capture(.intentCleanSucceeded(surface: .clipboard, telemetry: outcome.telemetry))
        StatsStore().record(outcome.telemetry)
        await IntentHistory.record(input: raw, output: outcome.cleaned, settings: settings)
        return .result(
            dialog: outcome.telemetry.changed
                ? "Cleaned your link."
                : "Your link was already clean."
        )
    }
}
#endif
