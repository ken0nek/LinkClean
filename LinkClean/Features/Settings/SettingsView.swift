//
//  SettingsView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import SwiftData
import SwiftUI
import LinkCleanKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKeys.autoPasteEnabled) private var autoPasteEnabled = true
    @AppStorage(SettingsKeys.saveHistoryEnabled, store: UserDefaults(suiteName: AppGroup.identifier)) private var saveHistoryEnabled = true
    @State private var showClearHistoryConfirmation = false
    @State private var showDisableHistoryConfirmation = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        Form {
            Section {
                Toggle("Auto Paste", isOn: $autoPasteEnabled)
                    .accessibilityIdentifier("settings-auto-paste-toggle")
            } header: {
                Text("Clipboard")
            } footer: {
                Text("When enabled, LinkClean automatically pastes a valid URL from your clipboard when you open the app or return to it.")
            }

            Section("Cleaning") {
                NavigationLink("Default parameters") {
                    ManageParametersView()
                }

                NavigationLink("Custom parameters") {
                    CustomParametersView()
                }
            }

            Section("Data") {
                Toggle("Save History", isOn: Binding(
                    get: { saveHistoryEnabled },
                    set: { newValue in
                        if newValue {
                            saveHistoryEnabled = true
                        } else {
                            showDisableHistoryConfirmation = true
                        }
                    }
                ))

                if saveHistoryEnabled {
                    Button("Clear History", role: .destructive) {
                        showClearHistoryConfirmation = true
                    }
                }
            }

            Section("How to Use") {
                Label("Open Safari or any app with a link", systemImage: "1.circle")
                Label("Tap the Share button", systemImage: "2.circle")
                Label("Select \"Clean URL\"", systemImage: "3.circle")
                Label("The cleaned URL is copied to your clipboard", systemImage: "4.circle")
            }

            Section("About") {
                LabeledContent("Version", value: "\(version) (\(build))")
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Settings")
        .alert("Disable History?", isPresented: $showDisableHistoryConfirmation) {
            Button("Disable & Delete", role: .destructive) {
                saveHistoryEnabled = false
                try? modelContext.delete(model: HistoryEntry.self)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All existing history will be permanently deleted.")
        }
        .alert("Clear History?", isPresented: $showClearHistoryConfirmation) {
            Button("Delete", role: .destructive) {
                try? modelContext.delete(model: HistoryEntry.self)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All cleaning history will be permanently deleted.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
