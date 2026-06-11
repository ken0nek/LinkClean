//
//  HistoryStoreTests.swift
//  LinkCleanDataTests
//

import Testing
import Foundation
import SwiftData
@testable import LinkCleanData
import LinkCleanCore
import LinkCleanTestSupport

@MainActor
struct HistoryStoreTests {

    private func makeStore(
        saveHistory: Bool = true,
        metadata: LinkMetadataService = StubLinkMetadataService()
    ) -> (store: HistoryStore, container: ModelContainer) {
        let container = HistoryContainer.makeInMemory()
        let settings = SettingsStore(appGroupSuiteName: "test.\(UUID().uuidString)")
        settings.saveHistoryEnabled = saveHistory
        return (HistoryStore(container: container, metadata: metadata, settings: settings), container)
    }

    private func count(_ container: ModelContainer) -> Int {
        (try? container.mainContext.fetchCount(FetchDescriptor<HistoryEntry>())) ?? -1
    }

    private func outcome() -> CleanOutcome {
        URLCleaner.outcome(for: "https://x.com/?utm_source=a&id=1", removing: ["utm_source"])
    }

    @Test func recordWritesARowWhenEnabled() {
        let (store, container) = makeStore(saveHistory: true)
        store.record(outcome())
        #expect(count(container) == 1)
    }

    @Test func recordSkipsWhenHistoryDisabled() {
        let (store, container) = makeStore(saveHistory: false)
        store.record(outcome())
        #expect(count(container) == 0)
    }

    @Test func deleteRemovesTheEntry() {
        let (store, container) = makeStore()
        let entry = HistoryEntry(input: "https://x.com?a=1", output: "https://x.com")
        container.mainContext.insert(entry)
        try? container.mainContext.save()

        store.delete(entry)

        #expect(count(container) == 0)
    }

    @Test func clearAllRemovesEverything() {
        let (store, container) = makeStore()
        for index in 0..<3 {
            container.mainContext.insert(HistoryEntry(input: "https://x.com?a=\(index)", output: "https://x.com/\(index)"))
        }
        try? container.mainContext.save()

        store.clearAll()

        #expect(count(container) == 0)
    }

    @Test func enrichPopulatesMetadataAndMarksAttempted() async {
        let (store, container) = makeStore(metadata: StubLinkMetadataService(title: "Example", thumbnailData: Data([1, 2, 3])))
        let entry = HistoryEntry(input: "https://x.com?a=1", output: "https://x.com")
        container.mainContext.insert(entry)

        store.enrich(entry)
        for _ in 0..<200 where !entry.metadataFetchAttempted {
            try? await Task.sleep(for: .milliseconds(5))
        }

        #expect(entry.pageTitle == "Example")
        #expect(entry.thumbnailData == Data([1, 2, 3]))
        #expect(entry.metadataFetchAttempted == true)
        #expect(store.enrichingIDs.isEmpty)
    }

    @Test func enrichSkipsAlreadyAttemptedEntries() {
        let (store, _) = makeStore()
        let entry = HistoryEntry(input: "https://x.com?a=1", output: "https://x.com", metadataFetchAttempted: true)

        store.enrich(entry)

        #expect(store.enrichingIDs.isEmpty) // never entered the pool
    }
}
