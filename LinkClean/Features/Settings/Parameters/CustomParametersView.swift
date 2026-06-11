//
//  CustomParametersView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import SwiftUI
import LinkCleanKit

struct CustomParametersView: View {
    @Environment(EntitlementsModel.self) private var entitlements
    @State private var viewModel: CustomParametersViewModel
    @State private var parameterPendingDelete: String?
    @State private var addErrorMessage: String?
    @State private var paywallTrigger: AnalyticsEvent.PaywallTrigger?

    init(viewModel: CustomParametersViewModel = CustomParametersViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    /// A free user who has used their one free rule — the Add affordance shows a
    /// lock and routes to the paywall instead of adding (§9-C). On a deliberate
    /// management screen a persistent lock is honest, unlike the Home pill (§9-B).
    /// The gate policy lives in the ViewModel; this only reads it for display.
    private var isAtFreeLimit: Bool {
        viewModel.isAtFreeLimit(entitlement: entitlements.entitlement)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            Section {
                HStack(spacing: 12) {
                    TextField(String(localized: .customParametersAddPlaceholder), text: $viewModel.newParameter)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .accessibilityIdentifier("custom-parameter-input")

                    Button {
                        switch viewModel.requestAddParameter(entitlement: entitlements.entitlement) {
                        case .gated(let trigger):
                            paywallTrigger = trigger
                        case .attempted(let error):
                            addErrorMessage = error
                        }
                    } label: {
                        Image(systemName: isAtFreeLimit ? "lock.fill" : "plus.circle.fill")
                            .imageScale(.large)
                    }
                    .disabled(!isAtFreeLimit && !viewModel.canAdd)
                    .accessibilityLabel(Text(.customParametersAddButton))
                    .accessibilityIdentifier("custom-parameter-add")
                }
            } header: {
                Text(.customParametersAddHeader)
            } footer: {
                if entitlements.entitlement != .pro {
                    Text(.customParametersFreeCounter(viewModel.customParameters.count, ProGate.freeCustomRuleAllowance))
                }
            }

            Section {
                if viewModel.customParameters.isEmpty {
                    Text(.customParametersListEmpty)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.customParameters, id: \.self) { parameter in
                        HStack {
                            Text(parameter)
                                .font(.system(.body, design: .monospaced))
                                .accessibilityIdentifier("custom-parameter-\(parameter)")

                            Spacer()

                            Button(role: .destructive) {
                                parameterPendingDelete = parameter
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(Text(.customParametersDelete(parameter)))
                            .accessibilityIdentifier("custom-parameter-delete-\(parameter)")
                        }
                    }
                    .onDelete(perform: viewModel.deleteParameters)
                }
            } header: {
                Text(.customParametersListHeader)
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle(Text(.customParametersTitle))
        .onAppear {
            viewModel.onAppear()
        }
        .paywallSheet(trigger: $paywallTrigger, entitlements: entitlements)
        .alert(
            Text(.customParametersAddErrorTitle),
            isPresented: Binding(
                get: { addErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        addErrorMessage = nil
                    }
                }
            )
        ) {
            Button(role: .cancel) {
                addErrorMessage = nil
            } label: {
                Text(.commonOk)
            }
        } message: {
            if let addErrorMessage {
                Text(addErrorMessage)
            }
        }
        .alert(
            Text(.customParametersDeleteConfirmTitle),
            isPresented: Binding(
                get: { parameterPendingDelete != nil },
                set: { isPresented in
                    if !isPresented {
                        parameterPendingDelete = nil
                    }
                }
            )
        ) {
            Button(role: .destructive) {
                if let parameterPendingDelete {
                    viewModel.removeParameter(parameterPendingDelete)
                }
                parameterPendingDelete = nil
            } label: {
                Text(.commonDelete)
            }
            Button(role: .cancel) {
                parameterPendingDelete = nil
            } label: {
                Text(.commonCancel)
            }
        } message: {
            if let parameterPendingDelete {
                Text(.customParametersDeleteConfirmMessage(parameterPendingDelete))
            }
        }
    }
}

#Preview {
    NavigationStack {
        CustomParametersView()
            .environment(EntitlementsModel.preview)
    }
}
