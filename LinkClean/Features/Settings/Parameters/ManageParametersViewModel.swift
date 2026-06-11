//
//  ManageParametersViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation
import Observation
import LinkCleanCore
import LinkCleanAnalytics
import LinkCleanData

@MainActor
@Observable
final class ManageParametersViewModel {
    var sections: [TrackingParameterSection] = []
    var searchText = ""
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

    /// `sections` narrowed to the parameters matching `searchText` — by display
    /// name, raw name, or a host in its scope (so "youtube" surfaces host-scoped
    /// rules) — with empty sections dropped. Returns every section unchanged when
    /// the query is empty. Mirrors `HistoryViewModel`'s `localizedStandardContains`
    /// filter (case- and diacritic-insensitive).
    var filteredSections: [TrackingParameterSection] {
        guard !searchText.isEmpty else { return sections }
        return sections.compactMap { section in
            let matches = section.parameters.filter { parameter in
                parameter.displayName.localizedStandardContains(searchText)
                    || parameter.name.localizedStandardContains(searchText)
                    || (parameter.hosts?.contains { $0.localizedStandardContains(searchText) } ?? false)
            }
            return matches.isEmpty ? nil : TrackingParameterSection(kind: section.kind, parameters: matches)
        }
    }

    func onAppear() {
        reload()
    }

    func isEnabled(_ name: String) -> Bool {
        let normalized = name.lowercased()
        return enabledLookup[normalized] ?? store.isEnabled(normalized)
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
