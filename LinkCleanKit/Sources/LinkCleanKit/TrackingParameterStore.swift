//
//  TrackingParameterStore.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation

public nonisolated struct TrackingParameterStore: Sendable {
    private let suiteName: String?
    private let disabledKey = "trackingParametersDisabled"
    /// User opt-ins for catalog names that ship `enabledByDefault: false`.
    /// Kept disjoint from the disabled set by `setEnabled`; only deviations
    /// from the catalog default are persisted.
    private let enabledKey = "trackingParametersEnabled"
    private let customKey = "trackingParametersCustom"

    public init(suiteName: String? = AppGroup.identifier) {
        self.suiteName = suiteName
    }

    public func isEnabled(_ name: String) -> Bool {
        let normalized = name.lowercased()
        if disabledParameters().contains(normalized) { return false }
        if enabledOverrides().contains(normalized) { return true }
        return TrackingParameterCatalog.definition(for: normalized)?.enabledByDefault ?? true
    }

    public func setEnabled(_ name: String, isEnabled: Bool) {
        let normalized = name.lowercased()
        var disabled = disabledParameters()
        var enabled = enabledOverrides()
        disabled.remove(normalized)
        enabled.remove(normalized)
        let enabledByDefault = TrackingParameterCatalog.definition(for: normalized)?.enabledByDefault ?? true
        if isEnabled != enabledByDefault {
            if isEnabled {
                enabled.insert(normalized)
            } else {
                disabled.insert(normalized)
            }
        }
        defaults.set(Array(disabled).sorted(), forKey: disabledKey)
        defaults.set(Array(enabled).sorted(), forKey: enabledKey)
    }

    /// The parameter names to strip from a URL whose host is `host`: catalog
    /// rules that are on (default state plus user overrides) and whose host
    /// scope matches, plus every custom parameter. Custom parameters are
    /// global and unconditional — adding one is the user's explicit "strip
    /// this everywhere", and it wins over a disabled catalog toggle of the
    /// same name. A `nil` host (unparseable URL) applies global rules only.
    public func enabledParameters(forHost host: String?) -> Set<String> {
        let disabled = disabledParameters()
        let enabled = enabledOverrides()
        let catalogNames = TrackingParameterCatalog.names(forHost: host) { definition in
            !disabled.contains(definition.name)
                && (enabled.contains(definition.name) || definition.enabledByDefault)
        }
        return catalogNames.union(customParameterSet())
    }

    /// Whether adding `name` as a custom parameter would change nothing: it
    /// already names a catalog rule that strips on every site (global scope,
    /// currently enabled). Scoped or off rules still gain something from a
    /// global custom entry, so they don't count. Backs the custom-parameters
    /// add flow's "already in default parameters" rejection.
    public func isRedundantCustomParameter(_ name: String) -> Bool {
        let normalized = name.lowercased()
        guard let definition = TrackingParameterCatalog.definition(for: normalized),
              definition.hosts == nil else { return false }
        return isEnabled(normalized)
    }

    public func customParameters() -> [String] {
        Array(customParameterSet()).sorted()
    }

    public func addCustomParameter(_ name: String) {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return }
        var stored = customParameterSet()
        guard stored.insert(normalized).inserted else { return }
        defaults.set(Array(stored).sorted(), forKey: customKey)
    }

    /// Deliberately leaves the disabled/enabled override sets alone: a custom
    /// parameter may share a name with a catalog rule (`t` added globally while
    /// the scoped rule is toggled off), and deleting the custom entry must not
    /// silently revert the user's separate toggle choice.
    public func removeCustomParameter(_ name: String) {
        let normalized = name.lowercased()
        var stored = customParameterSet()
        guard stored.remove(normalized) != nil else { return }
        defaults.set(Array(stored).sorted(), forKey: customKey)
    }

    public func sections() -> [TrackingParameterSection] {
        TrackingParameterCatalog.sections
    }

    /// Sorted names of default parameters the user has turned off.
    public func disabledParameterNames() -> [String] {
        Array(disabledParameters()).sorted()
    }

    /// Restores every catalog parameter to its shipped default state by
    /// clearing both the disabled set and the off-by-default opt-ins.
    public func resetDefaultParameterOverrides() {
        defaults.removeObject(forKey: disabledKey)
        defaults.removeObject(forKey: enabledKey)
    }

    /// Removes every user-added custom parameter.
    public func removeAllCustomParameters() {
        defaults.removeObject(forKey: customKey)
    }

    /// Lowercases `host` and strips a trailing root dot (`youtube.com.`), the
    /// form `TrackingParameterDefinition.appliesTo(host:)` expects.
    static func normalize(host: String?) -> String? {
        guard var host = host?.lowercased(), !host.isEmpty else { return nil }
        if host.hasSuffix(".") {
            host.removeLast()
        }
        return host.isEmpty ? nil : host
    }

    private func disabledParameters() -> Set<String> {
        let stored = defaults.array(forKey: disabledKey) as? [String] ?? []
        return Set(stored.map { $0.lowercased() })
    }

    private func enabledOverrides() -> Set<String> {
        let stored = defaults.array(forKey: enabledKey) as? [String] ?? []
        return Set(stored.map { $0.lowercased() })
    }

    private func customParameterSet() -> Set<String> {
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
