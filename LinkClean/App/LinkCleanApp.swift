//
//  LinkCleanApp.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/1/26.
//

import Foundation
import SwiftUI
import UIKit

@main
struct LinkCleanApp: App {
    init() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-uiTesting"),
              let bundleID = Bundle.main.bundleIdentifier else { return }

        UserDefaults.standard.removePersistentDomain(forName: bundleID)

        // Avoid the system "paste from ..." permission alert during UI tests by
        // making the clipboard content originate from this app.
        UIPasteboard.general.string = ""
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
