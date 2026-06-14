//
//  TemplateStoreTests.swift
//  LinkCleanDataTests
//

import Testing
import Foundation
import LinkCleanCore
@testable import LinkCleanData

struct TemplateStoreTests {
    /// A store over a throwaway suite, plus its name so the test can tear it down.
    private func makeStore() -> (store: TemplateStore, suite: String) {
        let suite = "test.templates.\(UUID().uuidString)"
        return (TemplateStore(suiteName: suite), suite)
    }

    private func custom(_ name: String, _ format: String) -> LinkTemplate {
        .custom(id: UUID(), name: name, format: format)
    }

    // MARK: - Custom CRUD

    @Test func startsEmpty() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        #expect(store.customTemplates().isEmpty)
        #expect(store.allTemplates() == LinkTemplate.builtins)
    }

    @Test func upsertAddsThenReplacesByID() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        var t = custom("Mine", "{link}")
        store.upsert(t)
        #expect(store.customTemplates() == [t])

        // Same id, edited → replaced, not duplicated.
        t.name = "Renamed"
        t.format = "{title}: {link}"
        store.upsert(t)
        #expect(store.customTemplates() == [t])
    }

    @Test func upsertIgnoresBuiltins() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        store.upsert(.markdownPreset)
        #expect(store.customTemplates().isEmpty) // presets are code constants, never persisted
    }

    @Test func deleteRemovesAndRoundTripsThroughDefaults() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        let a = custom("A", "{link}")
        let b = custom("B", "{title}")
        store.upsert(a)
        store.upsert(b)
        store.delete(a.id)

        // Re-read through a fresh store over the same suite (cross-process check).
        #expect(TemplateStore(suiteName: suite).customTemplates() == [b])
    }

    // MARK: - Active set

    @Test func defaultsToMarkdownActiveWhenUnset() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        #expect(store.activeTemplateIDs() == [LinkTemplate.markdownPreset.id])
        #expect(store.isActive(LinkTemplate.markdownPreset.id))
        #expect(!store.isActive(LinkTemplate.cleanPreset.id))
    }

    @Test func setActiveMaterializesSetKeepingDefaultMarkdown() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        store.setActive(LinkTemplate.htmlPreset.id, true)
        // Turning HTML on must not silently drop the default Markdown.
        #expect(store.activeTemplateIDs() == [LinkTemplate.markdownPreset.id, LinkTemplate.htmlPreset.id])
    }

    @Test func setActiveFalseCanEmptyTheSet() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        store.setActive(LinkTemplate.markdownPreset.id, false)
        #expect(store.activeTemplateIDs().isEmpty)
        #expect(!store.isActive(LinkTemplate.markdownPreset.id))
    }

    @Test func activeRoundTripsThroughDefaults() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        store.setActive(LinkTemplate.cleanPreset.id, true)
        store.setActive(LinkTemplate.markdownPreset.id, false)
        // Cross-process re-read.
        #expect(TemplateStore(suiteName: suite).activeTemplateIDs() == [LinkTemplate.cleanPreset.id])
    }

    @Test func deletingActiveCustomDropsItFromActive() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let mine = custom("Mine", "{title}\n{link}")
        store.upsert(mine)
        store.setActive(mine.id, true)
        store.delete(mine.id)
        #expect(!store.isActive(mine.id))
    }

    // MARK: - resolveActive (entitled, ordered, fail-closed — §4.3)

    @Test func resolveActiveDefaultsToMarkdown() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        #expect(store.resolveActive(tier: .free) == [.markdownPreset])
        #expect(store.resolveActive(tier: .pro) == [.markdownPreset])
    }

    @Test func resolveActiveReturnsEntitledActivesInDisplayOrder() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let mine = custom("Mine", "<{link}|{title}>")
        store.upsert(mine)
        store.setActive(LinkTemplate.cleanPreset.id, true)
        store.setActive(LinkTemplate.htmlPreset.id, true)
        store.setActive(mine.id, true)
        store.setActive(LinkTemplate.markdownPreset.id, false)
        // Presets in catalog order, then customs — for a Pro user.
        #expect(store.resolveActive(tier: .pro) == [.cleanPreset, .htmlPreset, mine])
    }

    @Test func resolveActiveFiltersProForFreeTier() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        store.setActive(LinkTemplate.markdownPreset.id, false) // isolate the two under test
        store.setActive(LinkTemplate.cleanPreset.id, true)     // free
        store.setActive(LinkTemplate.htmlPreset.id, true)      // Pro
        #expect(store.resolveActive(tier: .pro) == [.cleanPreset, .htmlPreset])
        // A free user only sees the free ones (no paywall, just filtered).
        #expect(store.resolveActive(tier: .free) == [.cleanPreset])
    }

    @Test func resolveActiveFloorsToMarkdownWhenAllFilteredOrEmpty() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        // Free user whose only active format is Pro → floors to Markdown.
        store.setActive(LinkTemplate.htmlPreset.id, true)
        store.setActive(LinkTemplate.markdownPreset.id, false)
        #expect(store.resolveActive(tier: .free) == [.markdownPreset])
        // Empty active set → also floors to Markdown.
        store.setActive(LinkTemplate.htmlPreset.id, false)
        #expect(store.resolveActive(tier: .pro) == [.markdownPreset])
    }
}
