//
//  CopyFormatsViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/14/26.
//

import Foundation
import Observation
import LinkCleanCore
import LinkCleanAnalytics
import LinkCleanData

/// Drives the "Copy Formats" screen: lists the built-in presets and the user's
/// custom templates, renders a live preview of each against a sample dirty link,
/// and tracks which templates are **active** — the formats the Copy action offers
/// (one ⇒ silent copy, two or more ⇒ the in-extension picker). The Pro line is
/// enforced here (`copy-as-you-want` §4.3): a free user can only toggle the free
/// formats active (Pro/custom rows show a lock → paywall), and authoring a custom
/// template gates before the editor opens, mirroring ``CustomParametersViewModel``.
@MainActor
@Observable
final class CopyFormatsViewModel {
    private(set) var templates: [LinkTemplate] = []
    /// The active template ids — stored (not computed) so SwiftUI observes toggles.
    private(set) var activeIDs: Set<UUID> = []
    @ObservationIgnored private let store: TemplateStore
    @ObservationIgnored private let analytics: AnalyticsService

    init(
        store: TemplateStore = TemplateStore(),
        analytics: AnalyticsService = TelemetryDeckAnalytics()
    ) {
        self.store = store
        self.analytics = analytics
        reload()
    }

    func onAppear() { reload() }

    /// The shipped presets (free first), for the "Formats" section.
    var presets: [LinkTemplate] { templates.filter(\.isBuiltin) }

    /// The user-authored templates, for the "Your Formats" section.
    var customTemplates: [LinkTemplate] { templates.filter { !$0.isBuiltin } }

    /// Whether `template` is one of the active formats the Copy action offers.
    func isActive(_ template: LinkTemplate) -> Bool { activeIDs.contains(template.id) }

    /// Toggles a format active/inactive. Only ever called for an *unlocked* row (a
    /// free user can't reach this for a Pro format — that row is a lock instead), so
    /// it never needs to gate.
    func setActive(_ template: LinkTemplate, _ active: Bool) {
        store.setActive(template.id, active)
        activeIDs = store.activeTemplateIDs()
    }

    /// Renders `template` against a representative dirty link so each row shows what
    /// it produces — the preview is the editor's whole point (`copy-as-you-want` §6.5).
    func preview(for template: LinkTemplate) -> String {
        TemplateRenderer.render(template, .sample)
    }

    /// Whether `template`'s row should show a lock for this user — a Pro template a
    /// free user hasn't unlocked. The view shows a toggle for unlocked rows and a
    /// lock (→ paywall) for locked ones.
    func isLocked(_ template: LinkTemplate, entitlement: Entitlement) -> Bool {
        template.requiresPro && entitlement != .pro
    }

    /// The "New Format" affordance: authoring a custom template is a Pro feature, so
    /// a free user gates here (before the editor opens — value isn't built then
    /// blocked). A Pro user is allowed straight through to a fresh draft.
    func requestNewCustom(entitlement: Entitlement) -> GateResult {
        entitlement == .pro ? .allowed : .gated(.formatPicker)
    }

    /// A fresh draft for the editor — a sensible Title + Link starter the user edits.
    func newDraft() -> LinkTemplate {
        .custom(id: UUID(), name: "", format: "{title}\n{link}")
    }

    /// Persists a draft from the editor. Creation was already gated at
    /// ``requestNewCustom`` (and an existing custom is the user's own, never clawed
    /// back), so this doesn't re-gate. A brand-new template is also activated, since
    /// authoring one signals intent to use it.
    func saveCustom(_ draft: LinkTemplate) {
        let trimmed = LinkTemplate.custom(
            id: draft.id,
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            format: draft.format
        )
        let isNew = !store.customTemplates().contains { $0.id == trimmed.id }
        store.upsert(trimmed)
        if isNew {
            store.setActive(trimmed.id, true)
        }
        reload()
    }

    func deleteCustom(_ template: LinkTemplate) {
        store.delete(template.id)
        reload()
    }

    private func reload() {
        templates = store.allTemplates()
        activeIDs = store.activeTemplateIDs()
    }
}
