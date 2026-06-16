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
    /// (``HistoryRecorder/save(input:output:in:)`` + ``HistoryContainer/makeShared()``)
    /// is MainActor-isolated in `LinkCleanData`; an intent's `perform()` awaits
    /// this, hopping over for the brief write.
    @MainActor
    static func record(input: String, output: String, settings: SettingsStore) {
        // Never persist the onboarding "Try it" practice link — parity with
        // `ActionPipeline.saveHistory`.
        guard !OnboardingDemo.matches(urlString: input) else { return }
        guard settings.saveHistoryEnabled, let container = HistoryContainer.makeShared() else {
            return
        }
        do {
            try HistoryRecorder.save(input: input, output: output, in: container)
        } catch {
            Log.intent.debug("history save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
#endif
