//
//  LinkCleanApp.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/1/26.
//

import Foundation
import LinkCleanCore
import LinkCleanAnalytics
import LinkCleanData
import SwiftData
import SwiftUI

@main
struct LinkCleanApp: App {
    private let modelContainer: ModelContainer
    @State private var entitlements: EntitlementsModel

    init() {
        self.modelContainer = HistoryContainer.makeShared() ?? HistoryContainer.makeInMemory()

        // Initialize analytics as early as possible (TelemetryDeck guidance: in
        // App.init, not onAppear). DEBUG builds are automatically test mode.
        if !DebugMode.isScreenshotMode {
            TelemetryDeckAnalytics.start(surface: "app")
        }

        // StoreKit 2 needs no configuration step or appUserID — the device is the
        // entitlement store of record for the lifetime non-consumable.
        let entitlementsService = StoreKitEntitlementsService()
        self._entitlements = State(initialValue: EntitlementsModel(service: entitlementsService))

        // All UI-test / screenshot / QA launch-argument handling lives in the
        // DEBUG-only configurator; production launches run none of it.
        #if DEBUG
        DebugLaunchConfigurator.apply(
            arguments: ProcessInfo.processInfo.arguments,
            container: modelContainer,
            settings: SettingsStore(),
            parameters: TrackingParameterStore()
        )
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(entitlements)
        }
        .modelContainer(modelContainer)
    }
}
