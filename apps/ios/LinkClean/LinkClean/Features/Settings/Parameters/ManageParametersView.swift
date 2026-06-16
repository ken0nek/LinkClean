//
//  ManageParametersView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import SwiftUI
import LinkCleanCore

struct ManageParametersView: View {
    @State private var viewModel: ManageParametersViewModel

    init(deps: AppDependencies) {
        _viewModel = State(initialValue: ManageParametersViewModel(deps: deps))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            ForEach(viewModel.filteredSections) { section in
                Section {
                    ForEach(section.parameters) { parameter in
                        Toggle(
                            isOn: Binding(
                                get: { viewModel.isEnabled(parameter.name) },
                                set: { viewModel.setEnabled(parameter.name, isEnabled: $0) }
                            )
                        ) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(parameter.displayName)
                                    .font(.system(.body, design: .monospaced))
                                if let hosts = parameter.hosts {
                                    Text(.defaultParametersHostScope(hosts.sorted().joined(separator: ", ")))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .tint(.accentColor)
                        .accessibilityIdentifier("parameter-toggle-\(parameter.name)")
                    }
                } header: {
                    parameterKindTitle(section.kind.id)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle(Text(.defaultParametersTitle))
        .searchable(text: $viewModel.searchText)
        .scrollDismissesKeyboard(.immediately)
        .overlay {
            if viewModel.filteredSections.isEmpty && !viewModel.searchText.isEmpty {
                ContentUnavailableView.search
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

#Preview {
    NavigationStack {
        ManageParametersView(deps: .preview())
    }
}
