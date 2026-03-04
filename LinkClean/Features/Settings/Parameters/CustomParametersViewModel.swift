//
//  CustomParametersViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation
import Observation
import LinkCleanKit

@MainActor
@Observable
final class CustomParametersViewModel {
    var customParameters: [String] = []
    var newParameter: String = ""
    @ObservationIgnored private let store: TrackingParameterStore

    init(store: TrackingParameterStore = TrackingParameterStore()) {
        self.store = store
        reload()
    }

    var canAdd: Bool {
        !normalizedInput.isEmpty
    }

    func onAppear() {
        reload()
    }

    func addParameter() -> String? {
        let normalized = normalizedInput
        guard !normalized.isEmpty else { return nil }
        if TrackingParameterCatalog.defaultEnabledSet.contains(normalized) {
            return "Already in default parameters."
        }
        if customParameters.contains(normalized) {
            return "Already in custom parameters."
        }
        store.addCustomParameter(normalized)
        newParameter = ""
        reload()
        return nil
    }

    func deleteParameters(at offsets: IndexSet) {
        let names = customParameters
        for index in offsets {
            store.removeCustomParameter(names[index])
        }
        reload()
    }

    func removeParameter(_ name: String) {
        store.removeCustomParameter(name)
        reload()
    }

    private var normalizedInput: String {
        newParameter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func reload() {
        customParameters = store.customParameters()
    }
}
