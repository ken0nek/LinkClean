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
    @State private var viewModel = SettingsViewModel()
    @State private var showClearHistoryConfirmation = false
    @State private var showDisableHistoryConfirmation = false

    #if DEBUG
    /// Production never auto-pushes; DEBUG screenshot/testing builds can land
    /// directly on Manage Parameters with `-push-parameters` (pairs with
    /// `-tab-settings`, mirroring ContentView's tab deep-links).
    @State private var isShowingParametersForScreenshot =
        ProcessInfo.processInfo.arguments.contains("-push-parameters")
    #endif

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.autoPasteEnabled },
                    set: { viewModel.setAutoPaste($0) }
                )) { Text(.settingsClipboardAutoPaste) }
                    .tint(.accentColor)
                    .accessibilityIdentifier("settings-auto-paste-toggle")
            } header: {
                Text(.settingsClipboardHeader)
            } footer: {
                Text(.settingsClipboardFooter)
            }

            Section {
                NavigationLink {
                    ManageParametersView()
                } label: {
                    Text(.settingsCleaningDefaultParameters)
                }

                NavigationLink {
                    CustomParametersView()
                } label: {
                    Text(.settingsCleaningCustomParameters)
                }
            } header: {
                Text(.settingsCleaningHeader)
            }

            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.saveHistoryEnabled },
                    set: { newValue in
                        if newValue {
                            viewModel.enableSaveHistory()
                        } else {
                            showDisableHistoryConfirmation = true
                        }
                    }
                )) {
                    Text(.settingsDataSaveHistory)
                }
                .tint(.accentColor)

                if viewModel.saveHistoryEnabled {
                    Button(role: .destructive) {
                        showClearHistoryConfirmation = true
                    } label: {
                        Text(.settingsDataClearHistory)
                    }
                }
            } header: {
                Text(.settingsDataHeader)
            }

            Section {
                NavigationLink {
                    ExtensionGuideView(source: .settings)
                        .navigationTitle(Text(.guideTitle))
                } label: {
                    Label { Text(.settingsHowToUseHeader) } icon: { Image(systemName: "wand.and.stars") }
                }
            }

            Section {
                LabeledContent {
                    Text(verbatim: "\(version) (\(build))")
                } label: {
                    Text(.settingsAboutVersion)
                }
            } header: {
                Text(.settingsAboutHeader)
            }

            #if DEBUG
            if !DebugMode.isScreenshotMode {
                Section {
                    NavigationLink {
                        DeveloperMenuView()
                    } label: {
                        Label { Text(verbatim: "Developer") } icon: { Image(systemName: "hammer") }
                    }
                }
            }
            #endif
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle(Text(.settingsTitle))
        #if DEBUG
        .navigationDestination(isPresented: $isShowingParametersForScreenshot) {
            ManageParametersView()
        }
        #endif
        .onAppear { viewModel.onAppear() }
        .alert(Text(.settingsDisableHistoryTitle), isPresented: $showDisableHistoryConfirmation) {
            Button(role: .destructive) {
                viewModel.disableSaveHistory(in: modelContext)
            } label: {
                Text(.settingsDisableHistoryConfirm)
            }
            Button(role: .cancel) {} label: { Text(.commonCancel) }
        } message: {
            Text(.settingsDisableHistoryMessage)
        }
        .alert(Text(.settingsClearHistoryTitle), isPresented: $showClearHistoryConfirmation) {
            Button(role: .destructive) {
                viewModel.clearHistory(in: modelContext)
            } label: {
                Text(.commonDelete)
            }
            Button(role: .cancel) {} label: { Text(.commonCancel) }
        } message: {
            Text(.settingsClearHistoryMessage)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
