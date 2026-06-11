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
                    sectionTitle(for: section.kind)
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

    /// Maps a catalog ``TrackingParameterKind`` id to its localized section
    /// title. The domain ships identifiers (`"utm"`); the title lives here, in
    /// the presenting layer, where the string catalog generates the symbols. An
    /// unknown id falls back to the raw identifier, exactly as the kit did.
    private func sectionTitle(for kind: TrackingParameterKind) -> Text {
        switch kind.id {
        case "utm": Text(.parametersKindUtm)
        case "common": Text(.parametersKindCommon)
        case "ads": Text(.parametersKindAds)
        case "analytics": Text(.parametersKindAnalytics)
        case "email": Text(.parametersKindEmail)
        case "social": Text(.parametersKindSocial)
        case "affiliate": Text(.parametersKindAffiliate)
        default: Text(verbatim: kind.id)
        }
    }
}

#Preview {
    NavigationStack {
        ManageParametersView(deps: .preview())
    }
}
