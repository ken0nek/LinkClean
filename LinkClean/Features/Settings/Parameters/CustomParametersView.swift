//
//  CustomParametersView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import SwiftUI

struct CustomParametersView: View {
    @State private var viewModel: CustomParametersViewModel
    @State private var parameterPendingDelete: String?
    @State private var addErrorMessage: String?

    init(viewModel: CustomParametersViewModel = CustomParametersViewModel()) {
        _viewModel = State(initialValue: viewModel)
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
                        addErrorMessage = viewModel.addParameter()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                    .disabled(!viewModel.canAdd)
                    .accessibilityLabel(Text(.customParametersAddButton))
                    .accessibilityIdentifier("custom-parameter-add")
                }
            } header: {
                Text(.customParametersAddHeader)
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
    }
}
