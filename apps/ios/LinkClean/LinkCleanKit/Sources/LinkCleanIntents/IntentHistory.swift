//
//  IntentHistory.swift
//  LinkCleanIntents
//
//  Created by Ken Tominaga on 6/12/26.
//

#if canImport(UIKit)
import Foundation
import LinkCleanCore
import LinkCleanData

/// Records an intent-driven clean to the shared History store — parity with the
/// action extensions, which persist every clean the same way
/// (``ActionPipeline``). Honors the user's Save History setting and is
/// best-effort: a failure is logged, never thrown, because the intent has
/// already done its job (the cleaned link is on the pasteboard / returned) and
/// must not fail just because persistence did.
enum IntentHistory {
    /// `@MainActor` because the shared SwiftData write
    /// (``HistoryRecorder/save(input:output:arrivedFromHost:in:)`` +
    /// ``HistoryContainer/makeShared()``) is MainActor-isolated in `LinkCleanData`;
    /// an intent's `perform()` awaits this, hopping over for the brief write.
    ///
    /// `original` is the link the user supplied (used only for the onboarding-demo
    /// guard); the row stores the cleaned-from *destination* (`outcome.input`) and
    /// the arrival host separately, so the before→after view diffs the destination's
    /// own params and still shows "Expanded from …".
    @MainActor
    static func record(original: String, outcome: CleanOutcome, settings: SettingsStore) {
        // Never persist the onboarding "Try it" practice link — parity with
        // `ActionPipeline.saveHistory`.
        guard !OnboardingDemo.matches(urlString: original) else { return }
        guard settings.saveHistoryEnabled, let container = HistoryContainer.makeShared() else {
            return
        }
        do {
            try HistoryRecorder.save(
                input: outcome.input,
                output: outcome.cleaned,
                arrivedFromHost: outcome.arrivedFromHost,
                in: container
            )
        } catch {
            Log.intent.debug("history save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
#endif
