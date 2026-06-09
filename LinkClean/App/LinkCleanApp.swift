//
//  LinkCleanApp.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/1/26.
//

import Foundation
import LinkCleanKit
import SwiftData
import SwiftUI
import UIKit

@main
struct LinkCleanApp: App {
    private let modelContainer: ModelContainer

    init() {
        self.modelContainer = HistoryContainer.makeShared() ?? HistoryContainer.makeInMemory()

        // Initialize analytics as early as possible (TelemetryDeck guidance: in
        // App.init, not onAppear). DEBUG builds are automatically test mode.
        TelemetryDeckAnalytics.start()

        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-uiTesting"),
           let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)

            // Bypass first-launch onboarding so existing UI tests land on the
            // main tabs. Must run after the domain wipe above, which clears it.
            UserDefaults.standard.set(true, forKey: SettingsKeys.hasCompletedOnboarding)

            // Avoid the system "paste from ..." permission alert during UI tests by
            // making the clipboard content originate from this app.
            UIPasteboard.general.string = ""
        }

        #if DEBUG
        // Screenshot/manual-testing helper: lands on the main tabs with a sample
        // dirty URL already on the clipboard. Writing it here (in-app) keeps the
        // subsequent auto-paste read same-origin, so iOS shows no paste banner.
        if arguments.contains("-seedSampleURL") {
            UserDefaults.standard.set(true, forKey: SettingsKeys.hasCompletedOnboarding)
            UIPasteboard.general.string =
                "https://www.example.com/products/sneakers?utm_source=newsletter&utm_medium=email&fbclid=abc123&gclid=xyz789&ref=promo&color=blue"
        }

        // Screenshot/manual-testing helper: populates a few representative history
        // rows (once, only when empty) so the History screen can be previewed.
        if arguments.contains("-seedHistory") {
            UserDefaults.standard.set(true, forKey: SettingsKeys.hasCompletedOnboarding)
            Self.seedSampleHistory(into: modelContainer)
        }
        #endif
    }

    #if DEBUG
    @MainActor
    private static func seedSampleHistory(into container: ModelContainer) {
        let context = container.mainContext
        let existing = (try? context.fetchCount(FetchDescriptor<HistoryEntry>())) ?? 0
        guard existing == 0 else { return }

        let samples: [(input: String, output: String, title: String?, ageHours: Double)] = [
            ("https://www.nytimes.com/2026/06/08/technology/ai-privacy.html?utm_source=newsletter&utm_campaign=daily",
             "https://www.nytimes.com/2026/06/08/technology/ai-privacy.html", "What AI Means for Your Privacy", 1),
            ("https://x.com/user/status/1799123456789?s=20&t=AbCdEf",
             "https://x.com/user/status/1799123456789", nil, 5),
            ("https://www.youtube.com/watch?v=dQw4w9WgXcQ&feature=share&utm_source=copy",
             "https://www.youtube.com/watch?v=dQw4w9WgXcQ", "Designing for Trust — a Talk", 28),
            ("https://store.example.com/products/wireless-headphones?ref=promo&fbclid=xyz789",
             "https://store.example.com/products/wireless-headphones", nil, 75),
        ]
        let now = Date()
        for sample in samples {
            context.insert(HistoryEntry(
                input: sample.input,
                output: sample.output,
                createdAt: now.addingTimeInterval(-sample.ageHours * 3600),
                pageTitle: sample.title,
                metadataFetchAttempted: true
            ))
        }
        // Flush now rather than waiting on autosave, so the rows are present the
        // moment the History @Query first reads.
        try? context.save()
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
