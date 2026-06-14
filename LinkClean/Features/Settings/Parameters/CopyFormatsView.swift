//
//  CopyFormatsView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/14/26.
//

import SwiftUI
import LinkCleanCore

/// "Copy Formats" (Settings): choose which link format the Copy action copies, and
/// author your own. Each row shows the format's name over a live preview of what it
/// produces for a sample dirty link. Free users get Clean Link + Markdown; a Pro
/// preset or a custom format routes through the paywall (`copy-as-you-want` §4.3) —
/// the gate decision lives in the ViewModel, this only maps it to the sheet.
struct CopyFormatsView: View {
    @Environment(EntitlementsModel.self) private var entitlements
    @State private var viewModel: CopyFormatsViewModel
    @State private var editorDraft: LinkTemplate?
    @State private var templatePendingDelete: LinkTemplate?
    @State private var paywallTrigger: AnalyticsEvent.PaywallTrigger?

    init(deps: AppDependencies) {
        _viewModel = State(initialValue: CopyFormatsViewModel(deps: deps))
    }

    var body: some View {
        Form {
            Section {
                ForEach(viewModel.presets) { preset in
                    formatRow(preset)
                }
            } header: {
                Text(.copyFormatsPresetsHeader)
            } footer: {
                Text(.copyFormatsPresetsFooter)
            }

            Section {
                if viewModel.customTemplates.isEmpty {
                    Text(.copyFormatsCustomEmpty)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.customTemplates) { template in
                        formatRow(template)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    templatePendingDelete = template
                                } label: {
                                    Label { Text(.commonDelete) } icon: { Image(systemName: "trash") }
                                }
                                Button {
                                    editorDraft = template
                                } label: {
                                    Label { Text(.copyFormatsEdit) } icon: { Image(systemName: "pencil") }
                                }
                                .tint(.accentColor)
                            }
                    }
                }

                Button {
                    switch viewModel.requestNewCustom(entitlement: entitlements.entitlement) {
                    case .allowed:
                        editorDraft = viewModel.newDraft()
                    case .gated(let trigger):
                        paywallTrigger = trigger
                    }
                } label: {
                    Label {
                        Text(.copyFormatsNew)
                    } icon: {
                        Image(systemName: entitlements.entitlement == .pro ? "plus.circle.fill" : "lock.fill")
                    }
                }
                .accessibilityIdentifier("copy-format-new")
            } header: {
                Text(.copyFormatsCustomHeader)
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle(Text(.copyFormatsTitle))
        .onAppear { viewModel.onAppear() }
        .sheet(item: $editorDraft) { draft in
            CopyFormatEditorView(draft: draft) { saved in
                viewModel.saveCustom(saved)
            }
        }
        .paywallSheet(trigger: $paywallTrigger, entitlements: entitlements)
        .alert(
            Text(.copyFormatsDeleteTitle),
            isPresented: Binding(
                get: { templatePendingDelete != nil },
                set: { if !$0 { templatePendingDelete = nil } }
            )
        ) {
            Button(role: .destructive) {
                if let template = templatePendingDelete {
                    viewModel.deleteCustom(template)
                }
                templatePendingDelete = nil
            } label: {
                Text(.commonDelete)
            }
            Button(role: .cancel) { templatePendingDelete = nil } label: { Text(.commonCancel) }
        } message: {
            if let template = templatePendingDelete {
                Text(.copyFormatsDeleteMessage(template.name))
            }
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private func formatRow(_ template: LinkTemplate) -> some View {
        let identifier = "copy-format-\(template.isBuiltin ? template.name : "custom-\(template.id.uuidString)")"
        if viewModel.isLocked(template, entitlement: entitlements.entitlement) {
            // Pro format a free user hasn't unlocked → a lock that routes to the paywall.
            Button {
                paywallTrigger = .formatPicker
            } label: {
                HStack(spacing: 12) {
                    nameAndPreview(template)
                    Spacer(minLength: 8)
                    Image(systemName: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(identifier)
        } else {
            // An entitled format → an Active toggle (active formats appear in the
            // Copy action; two or more active show the in-extension picker).
            Toggle(isOn: Binding(
                get: { viewModel.isActive(template) },
                set: { viewModel.setActive(template, $0) }
            )) {
                nameAndPreview(template)
            }
            .tint(.accentColor)
            .accessibilityIdentifier(identifier)
        }
    }

    private func nameAndPreview(_ template: LinkTemplate) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            copyFormatDisplayName(template)
                .foregroundStyle(.primary)
            Text(viewModel.preview(for: template))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.tail)
        }
    }
}

#Preview("Free") {
    NavigationStack {
        CopyFormatsView(deps: .preview(entitlement: .free))
            .environment(EntitlementsModel.preview)
    }
}

#Preview("Pro") {
    NavigationStack {
        CopyFormatsView(deps: .preview(entitlement: .pro))
            .environment(EntitlementsModel.previewPro)
    }
}
