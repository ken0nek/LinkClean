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
            Section("Add Custom Parameter") {
                HStack(spacing: 12) {
                    TextField("Parameter name", text: $viewModel.newParameter)
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
                    .accessibilityLabel("Add")
                    .accessibilityIdentifier("custom-parameter-add")
                }
            }

            Section("Custom Parameters") {
                if viewModel.customParameters.isEmpty {
                    Text("No custom parameters yet.")
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
                            .accessibilityLabel("Delete \(parameter)")
                            .accessibilityIdentifier("custom-parameter-delete-\(parameter)")
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Custom Parameters")
        .onAppear {
            viewModel.onAppear()
        }
        .alert(
            "Can't Add Parameter",
            isPresented: Binding(
                get: { addErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        addErrorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                addErrorMessage = nil
            }
        } message: {
            if let addErrorMessage {
                Text(addErrorMessage)
            }
        }
        .alert(
            "Delete Custom Parameter?",
            isPresented: Binding(
                get: { parameterPendingDelete != nil },
                set: { isPresented in
                    if !isPresented {
                        parameterPendingDelete = nil
                    }
                }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let parameterPendingDelete {
                    viewModel.removeParameter(parameterPendingDelete)
                }
                parameterPendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                parameterPendingDelete = nil
            }
        } message: {
            if let parameterPendingDelete {
                Text("This will remove \"\(parameterPendingDelete)\" from your custom parameters.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        CustomParametersView()
    }
}
