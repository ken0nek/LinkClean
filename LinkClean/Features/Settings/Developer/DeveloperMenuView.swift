//
//  DeveloperMenuView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

#if DEBUG
import SwiftData
import SwiftUI

/// DEBUG-only menu for inspecting and clearing the app's persisted state.
/// Strings are intentionally `verbatim` — this screen never ships to users, so
/// it stays out of the string catalog.
struct DeveloperMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DeveloperMenuViewModel()
    @State private var showResetEverythingConfirmation = false

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
        .task { viewModel.setModelContext(modelContext) }
        .onAppear { viewModel.refresh() }
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
    }
}
#endif
