//
//  DebugLaunchConfigurator.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/10/26.
//

#if DEBUG
import Foundation
import LinkCleanCore
import LinkCleanData
import SwiftData
import UIKit

/// Owns every launch-argument branch and fixture used by UI tests, screenshots,
/// and manual QA. Compiled only in DEBUG — production launches never reach this
/// code, and `LinkCleanApp.init` invokes ``apply(arguments:container:settings:parameters:)``
/// behind a single `#if DEBUG` once the real dependencies are wired.
///
/// Pure side effects on `UserDefaults`, the pasteboard, and the model container;
/// no return value. Each branch keys off one launch arg (`-uiTesting`,
/// `-seedSampleURL`, `-seedHistory`, `-forceReviewGate`) or ``DebugMode``. The
/// UI-test/test launch path always runs Debug (both schemes' test action builds
/// Debug), so nothing here needs to exist in Release.
enum DebugLaunchConfigurator {
    static func apply(
        arguments: [String],
        container: ModelContainer,
        settings: SettingsStore,
        parameters: TrackingParameterStore
    ) {
        if arguments.contains("-uiTesting"),
           let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)

            // Bypass first-launch onboarding so existing UI tests land on the
            // main tabs. Must run after the domain wipe above, which clears it.
            settings.hasCompletedOnboarding = true

            // Avoid the system "paste from ..." permission alert during UI tests by
            // making the clipboard content originate from this app.
            UIPasteboard.general.string = ""
        }

        if DebugMode.isScreenshotMode {
            prepareScreenshotState(settings: settings, parameters: parameters)
        }

        // Screenshot/manual-testing helper: lands on the main tabs with a sample
        // dirty URL already on the clipboard. Writing it here (in-app) keeps the
        // subsequent auto-paste read same-origin, so iOS shows no paste banner.
        if arguments.contains("-seedSampleURL") {
            settings.hasCompletedOnboarding = true
            UIPasteboard.general.string =
                "https://www.example.com/products/sneakers?utm_source=newsletter&utm_medium=email&fbclid=abc123&gclid=xyz789&ref=promo&color=blue"
        }

        // Screenshot/manual-testing helper: populates a few representative history
        // rows (once, only when empty) so the History screen can be previewed.
        if arguments.contains("-seedHistory") {
            settings.hasCompletedOnboarding = true
            seedSampleHistory(
                into: container,
                settings: settings,
                replacingExisting: DebugMode.isScreenshotMode
            )
        }

        // Review-prompt QA: while -forceReviewGate is present, bypass the
        // success/span/cooldown gating so the star sheet shows after the next copy
        // or share. Set unconditionally so a normal launch clears the persisted
        // flag rather than leaking it across runs.
        let forceReviewGate = arguments.contains("-forceReviewGate")
        DefaultReviewService().setDebugForceShow(forceReviewGate)
        if forceReviewGate {
            settings.hasCompletedOnboarding = true
        }
    }

    private static func prepareScreenshotState(
        settings: SettingsStore,
        parameters: TrackingParameterStore
    ) {
        settings.hasCompletedOnboarding = true
        settings.autoPasteEnabled = true
        settings.saveHistoryEnabled = true

        parameters.resetDefaultParameterOverrides()
        parameters.removeAllCustomParameters()
    }

    @MainActor
    private static func seedSampleHistory(
        into container: ModelContainer,
        settings: SettingsStore,
        replacingExisting: Bool = false
    ) {
        let context = container.mainContext
        if replacingExisting,
           let entries = try? context.fetch(FetchDescriptor<HistoryEntry>()) {
            for entry in entries {
                context.delete(entry)
            }
        }

        let existing = (try? context.fetchCount(FetchDescriptor<HistoryEntry>())) ?? 0
        guard existing == 0 else { return }

        // Every input→output pair mirrors what the default catalog actually
        // removes (host-scoped `si`/`s`/`t`/`feature` included), so a tapped
        // row stands up to scrutiny during review or QA. `thumbnail` names a
        // fixture PNG (pre-fetched real LinkPresentation metadata; regenerate
        // with scripts/fetch-history-thumbnails.swift) resolved against the
        // `-screenshotFixtures <dir>` launch arg the capture script passes —
        // without it rows fall back to monograms, as plain `-seedHistory`
        // launches always have.
        let samples: [(input: String, output: String, title: String?, thumbnail: String?, ageHours: Double)] = [
            ("https://www.youtube.com/watch?v=aqz-KE-bpKQ&si=kT4mXcVbN2aQ8sWd&feature=share",
             "https://www.youtube.com/watch?v=aqz-KE-bpKQ",
             "Big Buck Bunny 60fps 4K - Official Blender Foundation Short Film", "youtube", 0.6),
            ("https://x.com/user/status/1799123456789?s=20&t=kQ9rXcVb2aQ",
             "https://x.com/user/status/1799123456789", nil, nil, 2),
            ("https://medium.com/design-notes/calm-by-default-designing-quieter-apps-9f3c21ab47de?utm_source=newsletter&utm_medium=email",
             "https://medium.com/design-notes/calm-by-default-designing-quieter-apps-9f3c21ab47de",
             "Calm by Default: Designing Quieter Apps", "medium", 5),
            ("https://www.reddit.com/r/privacy/comments/1d4k9xz/whats_actually_inside_a_share_link/?utm_source=share&utm_medium=ios_app&utm_name=iossmf",
             "https://www.reddit.com/r/privacy/comments/1d4k9xz/whats_actually_inside_a_share_link/",
             "What's actually inside a share link? : r/privacy", "reddit", 9),
            ("https://www.nytimes.com/2026/06/08/technology/ai-privacy.html?utm_source=newsletter&utm_campaign=daily",
             "https://www.nytimes.com/2026/06/08/technology/ai-privacy.html",
             "What AI Means for Your Privacy", "nytimes", 26),
            ("https://open.spotify.com/episode/3nT8qLmV0yXcW9rB1kZdQe?si=XcVbN2aQ8sWd",
             "https://open.spotify.com/episode/3nT8qLmV0yXcW9rB1kZdQe",
             "Where Shared Links End Up — Privacy, Explained", nil, 31),
            ("https://www.theverge.com/2026/6/7/24293180/link-tracking-parameters-explainer?utm_campaign=social&utm_source=threads",
             "https://www.theverge.com/2026/6/7/24293180/link-tracking-parameters-explainer",
             "The invisible passengers in your links", "theverge", 52),
            ("https://en.wikipedia.org/wiki/UTM_parameters?utm_source=chatgpt.com",
             "https://en.wikipedia.org/wiki/UTM_parameters", "UTM parameters", "wikipedia", 76),
            ("https://store.example.com/products/wireless-headphones?fbclid=PAxy7zKw9q&gclid=EAIaIQ8b",
             "https://store.example.com/products/wireless-headphones", nil, nil, 101),
        ]

        let fixturesDirectory = settings.screenshotFixturesPath
            .map { URL(fileURLWithPath: $0, isDirectory: true) }

        let now = Date()
        for sample in samples {
            var thumbnailData: Data?
            if let fixturesDirectory, let thumbnail = sample.thumbnail {
                thumbnailData = try? Data(
                    contentsOf: fixturesDirectory.appendingPathComponent("\(thumbnail).png")
                )
            }
            context.insert(HistoryEntry(
                input: sample.input,
                output: sample.output,
                createdAt: now.addingTimeInterval(-sample.ageHours * 3600),
                pageTitle: sample.title,
                thumbnailData: thumbnailData,
                metadataFetchAttempted: true
            ))
        }
        // Flush now rather than waiting on autosave, so the rows are present the
        // moment the History @Query first reads.
        try? context.save()
    }
}
#endif
