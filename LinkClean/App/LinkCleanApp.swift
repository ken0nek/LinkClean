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
    private let dependencies: AppDependencies

    init() {
        self.modelContainer = HistoryContainer.makeShared() ?? HistoryContainer.makeInMemory()

        // The single production wiring path: constructs every service (StoreKit 2
        // needs no configuration step or appUserID) and starts the analytics SDK
        // as early as TelemetryDeck wants (App.init, not onAppear), screenshot
        // builds excepted. The whole object graph is reviewable in `live()`.
        self.dependencies = AppDependencies.live(container: modelContainer)

        // All UI-test / screenshot / QA launch-argument handling lives in the
        // DEBUG-only configurator; production launches run none of it. It mutates
        // the same store instances the app uses.
        #if DEBUG
        DebugLaunchConfigurator.apply(
            arguments: ProcessInfo.processInfo.arguments,
            container: modelContainer,
            settings: dependencies.settings,
            parameters: dependencies.parameters
        )
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView(deps: dependencies)
                .environment(dependencies.entitlements)
        }
        .modelContainer(modelContainer)
    }
}
