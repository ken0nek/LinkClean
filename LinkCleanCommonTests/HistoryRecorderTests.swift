//
//  HistoryRecorderTests.swift
//  LinkCleanCommonTests
//
//  Created by Ken Tominaga on 2/4/26.
//

import Testing
import Foundation
import SwiftData
@testable import LinkCleanCommon

struct HistoryRecorderTests {

    @Test func savePersistsSingleEntry() throws {
        let container = HistoryContainer.makeInMemory()
        try HistoryRecorder.save(input: "https://example.com?utm_source=twitter", output: "https://example.com", in: container)

        let context = ModelContext(container)
        let entries = try context.fetch(FetchDescriptor<HistoryEntry>())

        #expect(entries.count == 1)
        #expect(entries[0].input == "https://example.com?utm_source=twitter")
        #expect(entries[0].output == "https://example.com")
        #expect(entries[0].createdAt <= .now)
    }

    @Test func multipleSavesCreateMultipleEntries() throws {
        let container = HistoryContainer.makeInMemory()
        try HistoryRecorder.save(input: "https://a.com?fbclid=1", output: "https://a.com", in: container)
        try HistoryRecorder.save(input: "https://b.com?gclid=2", output: "https://b.com", in: container)

        let context = ModelContext(container)
        let entries = try context.fetch(FetchDescriptor<HistoryEntry>())

        #expect(entries.count == 2)
    }

    @Test func entriesHaveUniqueIDs() throws {
        let container = HistoryContainer.makeInMemory()
        try HistoryRecorder.save(input: "https://a.com?ref=x", output: "https://a.com", in: container)
        try HistoryRecorder.save(input: "https://b.com?ref=y", output: "https://b.com", in: container)

        let context = ModelContext(container)
        let entries = try context.fetch(FetchDescriptor<HistoryEntry>())

        #expect(entries[0].id != entries[1].id)
    }
}
