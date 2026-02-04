//
//  SettingsView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.autoPasteEnabled) private var autoPasteEnabled = true

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        Form {
            Section("About") {
                LabeledContent("Version", value: "\(version) (\(build))")
            }

            Section {
                Toggle("Auto Paste", isOn: $autoPasteEnabled)
                    .accessibilityIdentifier("settings-auto-paste-toggle")
            } header: {
                Text("Clipboard")
            } footer: {
                Text("When enabled, LinkClean automatically pastes a valid URL from your clipboard when you open the app or return to it.")
            }

            Section("How to Use") {
                Label("Open Safari or any app with a link", systemImage: "1.circle")
                Label("Tap the Share button", systemImage: "2.circle")
                Label("Select \"Clean URL\"", systemImage: "3.circle")
                Label("The cleaned URL is copied to your clipboard", systemImage: "4.circle")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
