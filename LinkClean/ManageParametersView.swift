//
//  ManageParametersView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import SwiftUI
import LinkCleanCommon

struct ManageParametersView: View {
    @State private var viewModel: ManageParametersViewModel

    init(viewModel: ManageParametersViewModel = ManageParametersViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            ForEach(viewModel.sections) { section in
                Section(section.kind.title) {
                    ForEach(section.parameters) { parameter in
                        Toggle(
                            parameter.displayName,
                            isOn: Binding(
                                get: { viewModel.isEnabled(parameter.name) },
                                set: { viewModel.setEnabled(parameter.name, isEnabled: $0) }
                            )
                        )
                        .font(.system(.body, design: .monospaced))
                        .accessibilityIdentifier("parameter-toggle-\(parameter.name)")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Default Parameters")
        .onAppear {
            viewModel.onAppear()
        }
    }
}

#Preview {
    NavigationStack {
        ManageParametersView()
    }
}
