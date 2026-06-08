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
    @ObservationIgnored private let analytics: AnalyticsService

    init(
        store: TrackingParameterStore = TrackingParameterStore(),
        analytics: AnalyticsService = TelemetryDeckAnalytics()
    ) {
        self.store = store
        self.analytics = analytics
        reload()
    }

    var canAdd: Bool {
        !normalizedInput.isEmpty
    }

    func onAppear() {
        reload()
        analytics.capture(.parametersCustomShown)
    }

    func addParameter() -> String? {
        let normalized = normalizedInput
        guard !normalized.isEmpty else { return nil }
        if TrackingParameterCatalog.defaultEnabledSet.contains(normalized) {
            return String(localized: .customParametersAddErrorAlreadyDefault)
        }
        if customParameters.contains(normalized) {
            return String(localized: .customParametersAddErrorAlreadyCustom)
        }
        store.addCustomParameter(normalized)
        newParameter = ""
        reload()
        analytics.capture(.parametersCustomAdded(totalCount: customParameters.count))
        return nil
    }

    func deleteParameters(at offsets: IndexSet) {
        let names = customParameters
        for index in offsets {
            store.removeCustomParameter(names[index])
        }
        reload()
        analytics.capture(.parametersCustomDeleted(totalCount: customParameters.count))
    }

    func removeParameter(_ name: String) {
        store.removeCustomParameter(name)
        reload()
        analytics.capture(.parametersCustomDeleted(totalCount: customParameters.count))
    }

    private var normalizedInput: String {
        newParameter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func reload() {
        customParameters = store.customParameters()
    }
}
