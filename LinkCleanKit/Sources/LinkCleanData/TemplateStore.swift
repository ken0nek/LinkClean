//
//  TemplateStore.swift
//  LinkCleanData
//
//  Created by Ken Tominaga on 6/14/26.
//

import Foundation
import LinkCleanCore

/// Cross-process storage for the "Copy as you want" link formats: the user's
/// custom ``LinkTemplate``s (a JSON blob) and which template the Copy action
/// renders by default. Written by the in-app editor, read by both the app and the
/// Copy action extension — the same App Group `UserDefaults` pattern as
/// ``StatsStore`` / ``TrackingParameterStore``.
///
/// Built-in presets are code constants (``LinkTemplate/builtins``), never
/// persisted; only user-authored templates and the selected-id live here.
public nonisolated struct TemplateStore: Sendable {
    // Store the suite *name* (Sendable), not the `UserDefaults` instance — same as
    // the sibling stores. `UserDefaults` caches one shared instance per suite, so
    // resolving it per access is cheap.
    private let suiteName: String?

    public init(suiteName: String? = AppGroup.identifier) {
        self.suiteName = suiteName
    }

    // MARK: - Custom templates

    /// The user-authored templates, in saved order (empty when none / on decode
    /// failure — the store is best-effort, like the rest of the App Group state).
    public func customTemplates() -> [LinkTemplate] {
        guard let data = defaults.data(forKey: SettingsKeys.copyFormatCustomTemplates),
              let templates = try? JSONDecoder().decode([LinkTemplate].self, from: data)
        else {
            return []
        }
        return templates
    }

    /// Every template the editor lists: the shipped presets first, then the user's
    /// custom templates.
    public func allTemplates() -> [LinkTemplate] {
        LinkTemplate.builtins + customTemplates()
    }

    /// Inserts a new custom template or replaces the existing one with the same id.
    /// Built-ins are code constants and silently ignored (never persisted).
    public func upsert(_ template: LinkTemplate) {
        guard !template.isBuiltin else { return }
        var templates = customTemplates()
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
        persist(templates)
    }

    /// Removes the custom template with `id`, and drops it from the active set so
    /// ``resolveActive(tier:)`` can't dangle on a deleted template.
    public func delete(_ id: UUID) {
        var templates = customTemplates()
        templates.removeAll { $0.id == id }
        persist(templates)
        var active = activeTemplateIDs()
        if active.remove(id) != nil {
            persistActive(active)
        }
    }

    // MARK: - Active set

    /// The ids the user has marked **active** — the formats the Copy action offers
    /// (one ⇒ silent copy, two or more ⇒ the in-extension picker). When the key was
    /// never written, defaults to Markdown active so a fresh install copies Markdown
    /// silently (the action's shipped behavior).
    public func activeTemplateIDs() -> Set<UUID> {
        guard let raw = defaults.array(forKey: SettingsKeys.copyFormatActiveTemplates) as? [String] else {
            return [LinkTemplate.markdownPreset.id]
        }
        return Set(raw.compactMap(UUID.init(uuidString:)))
    }

    public func isActive(_ id: UUID) -> Bool {
        activeTemplateIDs().contains(id)
    }

    /// Activates or deactivates a template. The first write materializes the set
    /// (including the default Markdown), so toggling another format on never
    /// silently drops Markdown.
    public func setActive(_ id: UUID, _ active: Bool) {
        var ids = activeTemplateIDs()
        if active {
            ids.insert(id)
        } else {
            ids.remove(id)
        }
        persistActive(ids)
    }

    /// The active formats the Copy action should offer a user on `tier`, in display
    /// order (presets first, then customs). Applies the §4.3 fail-closed fallback:
    /// Pro templates are filtered out for a `.free` user (stale snapshot, future
    /// shared-template import, family-sharing churn), and an empty result floors to
    /// the free Markdown default so the action always produces something. Centralized
    /// here so the app editor and the extension always agree.
    public func resolveActive(tier: Entitlement) -> [LinkTemplate] {
        let ids = activeTemplateIDs()
        let active = allTemplates().filter { template in
            ids.contains(template.id) && (!template.requiresPro || tier == .pro)
        }
        return active.isEmpty ? [.freeFallback] : active
    }

    // MARK: - Storage

    private func persist(_ templates: [LinkTemplate]) {
        guard let data = try? JSONEncoder().encode(templates) else { return }
        defaults.set(data, forKey: SettingsKeys.copyFormatCustomTemplates)
    }

    private func persistActive(_ ids: Set<UUID>) {
        defaults.set(ids.map(\.uuidString).sorted(), forKey: SettingsKeys.copyFormatActiveTemplates)
    }

    private var defaults: UserDefaults {
        guard let suiteName, let defaults = UserDefaults(suiteName: suiteName) else {
            return .standard
        }
        return defaults
    }
}
