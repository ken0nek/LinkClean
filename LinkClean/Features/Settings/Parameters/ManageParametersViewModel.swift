//
//  ManageParametersViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation
import Observation
import LinkCleanKit

@MainActor
@Observable
final class ManageParametersViewModel {
    var sections: [TrackingParameterSection] = []
    private var enabledLookup: [String: Bool] = [:]
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

    func onAppear() {
        reload()
    }

    func isEnabled(_ name: String) -> Bool {
        enabledLookup[name.lowercased()] ?? true
    }

    func setEnabled(_ name: String, isEnabled: Bool) {
        let normalized = name.lowercased()
        enabledLookup[normalized] = isEnabled
        store.setEnabled(normalized, isEnabled: isEnabled)
        analytics.capture(.parametersDefaultToggled(parameter: normalized, enabled: isEnabled))
    }

    private func reload() {
        let sections = store.sections()
        self.sections = sections

        var lookup: [String: Bool] = [:]
        for section in sections {
            for parameter in section.parameters {
                lookup[parameter.name] = store.isEnabled(parameter.name)
            }
        }
        enabledLookup = lookup
    }
}
