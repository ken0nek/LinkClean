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

        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-uiTesting"),
           let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)

            // Avoid the system "paste from ..." permission alert during UI tests by
            // making the clipboard content originate from this app.
            UIPasteboard.general.string = ""
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
