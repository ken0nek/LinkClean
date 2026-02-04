//
//  TrackingParameterStore.swift
//  LinkCleanCommon
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation

public nonisolated struct TrackingParameterStore: Sendable {
    private let suiteName: String?
    private let disabledKey = "trackingParametersDisabled"
    private let customKey = "trackingParametersCustom"

    public init(suiteName: String? = AppGroup.identifier) {
        self.suiteName = suiteName
    }

    public func isEnabled(_ name: String) -> Bool {
        let normalized = name.lowercased()
        return !disabledParameters().contains(normalized)
    }

    public func setEnabled(_ name: String, isEnabled: Bool) {
        let normalized = name.lowercased()
        var disabled = disabledParameters()
        if isEnabled {
            disabled.remove(normalized)
        } else {
            disabled.insert(normalized)
        }
        defaults.set(Array(disabled).sorted(), forKey: disabledKey)
    }

    public func enabledParameters() -> Set<String> {
        TrackingParameterCatalog.defaultEnabledSet
            .union(customParameters())
            .subtracting(disabledParameters())
    }

    public func sections() -> [TrackingParameterSection] {
        TrackingParameterCatalog.sections
    }

    private func disabledParameters() -> Set<String> {
        let stored = defaults.array(forKey: disabledKey) as? [String] ?? []
        return Set(stored.map { $0.lowercased() })
    }

    private func customParameters() -> Set<String> {
        let stored = defaults.array(forKey: customKey) as? [String] ?? []
        return Set(stored.map { $0.lowercased() })
    }

    private var defaults: UserDefaults {
        guard let suiteName, let defaults = UserDefaults(suiteName: suiteName) else {
            return .standard
        }
        return defaults
    }
}
