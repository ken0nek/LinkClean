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

    /// Whether a free user has used their one custom-rule allowance (T3): past it
    /// the Add affordance shows a lock and routes to the paywall. Display state for
    /// the view's icon/disabled; the policy (``ProGate``) lives here, not in the
    /// view.
    func isAtFreeLimit(entitlement: Entitlement) -> Bool {
        !ProGate.canAddCustomRule(entitlement: entitlement, currentCount: customParameters.count)
    }

    /// The Add button's full decision: gate to the paywall when the free allowance
    /// is used up (T3), otherwise attempt the add and surface any validation error.
    /// Keeps the entitlement + count + ``ProGate`` policy out of the view closure
    /// (P10); the view maps the result to the paywall trigger or the error alert.
    func requestAddParameter(entitlement: Entitlement) -> CustomParameterAddResult {
        guard !isAtFreeLimit(entitlement: entitlement) else {
            return .gated(.customParamSettings)
        }
        return .attempted(error: addParameter())
    }

    func addParameter() -> String? {
        let normalized = normalizedInput
        guard !normalized.isEmpty else { return nil }
        // Reject only when adding would change nothing (the rule already
        // strips on every site). A scoped rule (`t` on x.com) or an off/
        // disabled one still gains a global custom entry — that's the
        // leftover-pill path opting into "strip this on every site".
        if store.isRedundantCustomParameter(normalized) {
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
