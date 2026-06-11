//
//  DeveloperMenuView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

#if DEBUG
import SwiftData
import SwiftUI
import LinkCleanCore

/// DEBUG-only menu for inspecting and clearing the app's persisted state.
/// Strings are intentionally `verbatim` — this screen never ships to users, so
/// it stays out of the string catalog.
struct DeveloperMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(EntitlementsModel.self) private var entitlements
    @State private var viewModel = DeveloperMenuViewModel()
    @State private var showResetEverythingConfirmation = false
    @State private var previewTrigger: AnalyticsEvent.PaywallTrigger?

    var body: some View {
        Form {
            Section {
                resetRow("Auto Paste", value: viewModel.autoPaste, reset: viewModel.resetAutoPaste)
                resetRow("Onboarding Completed", value: viewModel.onboardingCompleted, reset: viewModel.resetOnboarding)
            } header: {
                Text(verbatim: "UserDefaults · Standard")
            }

            Section {
                resetRow("Save History", value: viewModel.saveHistory, reset: viewModel.resetSaveHistory)
                resetRow("Last Extension Run", value: viewModel.lastExtensionRun, reset: viewModel.resetLastExtensionRun)
                resetRow("Default Parameters", value: viewModel.disabledParameters, reset: viewModel.resetDefaultParameters)
                resetRow("Custom Parameters", value: viewModel.customParameters, reset: viewModel.clearCustomParameters)
            } header: {
                Text(verbatim: "UserDefaults · App Group")
            }

            Section {
                resetRow("History", value: viewModel.historyCount, reset: viewModel.clearHistory)
            } header: {
                Text(verbatim: "SwiftData")
            }

            Section {
                ForEach([AnalyticsEvent.PaywallTrigger.settingsRow, .historyArchive, .customParamHome], id: \.rawValue) { trigger in
                    Button {
                        previewTrigger = trigger
                    } label: {
                        Text(verbatim: "Preview Paywall · \(trigger.rawValue)")
                    }
                }

                Picker(selection: Binding(
                    get: { entitlements.debugOverrideValue },
                    set: { entitlements.debugSetOverride($0) }
                )) {
                    Text(verbatim: "Off (StoreKit)").tag(Entitlement?.none)
                    Text(verbatim: "Free").tag(Optional(Entitlement.free))
                    Text(verbatim: "Pro").tag(Optional(Entitlement.pro))
                } label: {
                    Text(verbatim: "Entitlement Override")
                }

                LabeledContent {
                    Text(verbatim: entitlements.entitlement.rawValue)
                        .foregroundStyle(.secondary)
                } label: {
                    Text(verbatim: "Resolved entitlement")
                }
            } header: {
                Text(verbatim: "Pro / Entitlements")
            }

            Section {
                Button(role: .destructive) {
                    showResetEverythingConfirmation = true
                } label: {
                    Text(verbatim: "Reset Everything")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle(Text(verbatim: "Developer"))
        .navigationBarTitleDisplayMode(.inline)
        .paywallSheet(trigger: $previewTrigger, entitlements: entitlements)
        .task { viewModel.setModelContext(modelContext) }
        .confirmationDialog(
            Text(verbatim: "Reset every stored value and clear History?"),
            isPresented: $showResetEverythingConfirmation,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                viewModel.resetEverything()
            } label: {
                Text(verbatim: "Reset Everything")
            }
            Button(role: .cancel) {} label: { Text(verbatim: "Cancel") }
        }
    }

    private func resetRow(_ title: String, value: String, reset: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: title)
                Text(verbatim: value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospaced()
            }

            Spacer()

            Button(role: .destructive) {
                reset()
            } label: {
                Text(verbatim: "Reset")
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    NavigationStack {
        DeveloperMenuView()
            .environment(EntitlementsModel.preview)
    }
}
#endif
