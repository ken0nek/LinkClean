//
//  HistoryViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
import SwiftData
import UIKit
@testable import LinkClean
import LinkCleanKit

@MainActor
struct HistoryViewModelTests {

    private func makeEntries() -> [HistoryEntry] {
        let container = HistoryContainer.makeInMemory()
        let context = ModelContext(container)

        let entries = [
            HistoryEntry(input: "https://example.com?utm_source=tw", output: "https://example.com", pageTitle: "Example Site"),
            HistoryEntry(input: "https://apple.com?fbclid=abc", output: "https://apple.com", pageTitle: "Apple"),
            HistoryEntry(input: "https://github.com?ref=home", output: "https://github.com", pageTitle: nil),
        ]
        for entry in entries {
            context.insert(entry)
        }
        return entries
    }

    @Test func filteredReturnsAllWhenSearchEmpty() {
        let vm = HistoryViewModel(metadataService: MockLinkMetadataService())
        let entries = makeEntries()

        vm.searchText = ""
        let result = vm.filteredEntries(from: entries)

        #expect(result.count == entries.count)
    }

    @Test func filteredMatchesPageTitle() {
        let vm = HistoryViewModel(metadataService: MockLinkMetadataService())
        let entries = makeEntries()

        vm.searchText = "Apple"
        let result = vm.filteredEntries(from: entries)

        #expect(result.count == 1)
        #expect(result.first?.pageTitle == "Apple")
    }

    @Test func filteredMatchesOutput() {
        let vm = HistoryViewModel(metadataService: MockLinkMetadataService())
        let entries = makeEntries()

        vm.searchText = "github"
        let result = vm.filteredEntries(from: entries)

        #expect(result.count == 1)
        #expect(result.first?.output == "https://github.com")
    }

    @Test func filteredIsCaseInsensitive() {
        let vm = HistoryViewModel(metadataService: MockLinkMetadataService())
        let entries = makeEntries()

        vm.searchText = "aPpLe"
        let result = vm.filteredEntries(from: entries)

        #expect(result.count == 1)
    }

    @Test func filteredReturnsEmptyOnNoMatch() {
        let vm = HistoryViewModel(metadataService: MockLinkMetadataService())
        let entries = makeEntries()

        vm.searchText = "zzzznotfound"
        let result = vm.filteredEntries(from: entries)

        #expect(result.isEmpty)
    }

    @Test func viewStateDisabled() {
        let vm = HistoryViewModel(metadataService: MockLinkMetadataService())

        let suiteName = AppGroup.identifier
        let defaults = UserDefaults(suiteName: suiteName)
        let originalValue = defaults?.object(forKey: SettingsKeys.saveHistoryEnabled)
        defaults?.set(false, forKey: SettingsKeys.saveHistoryEnabled)
        defer {
            if let originalValue {
                defaults?.set(originalValue, forKey: SettingsKeys.saveHistoryEnabled)
            } else {
                defaults?.removeObject(forKey: SettingsKeys.saveHistoryEnabled)
            }
        }

        vm.refreshSettings()

        #expect(vm.viewState(hasEntries: true) == .disabled)
    }

    @Test func viewStateEmpty() {
        let vm = HistoryViewModel(metadataService: MockLinkMetadataService())

        let suiteName = AppGroup.identifier
        let defaults = UserDefaults(suiteName: suiteName)
        let originalValue = defaults?.object(forKey: SettingsKeys.saveHistoryEnabled)
        defaults?.set(true, forKey: SettingsKeys.saveHistoryEnabled)
        defer {
            if let originalValue {
                defaults?.set(originalValue, forKey: SettingsKeys.saveHistoryEnabled)
            } else {
                defaults?.removeObject(forKey: SettingsKeys.saveHistoryEnabled)
            }
        }

        vm.refreshSettings()

        #expect(vm.viewState(hasEntries: false) == .empty)
    }

    @Test func viewStatePopulated() {
        let vm = HistoryViewModel(metadataService: MockLinkMetadataService())

        let suiteName = AppGroup.identifier
        let defaults = UserDefaults(suiteName: suiteName)
        let originalValue = defaults?.object(forKey: SettingsKeys.saveHistoryEnabled)
        defaults?.set(true, forKey: SettingsKeys.saveHistoryEnabled)
        defer {
            if let originalValue {
                defaults?.set(originalValue, forKey: SettingsKeys.saveHistoryEnabled)
            } else {
                defaults?.removeObject(forKey: SettingsKeys.saveHistoryEnabled)
            }
        }

        vm.refreshSettings()

        #expect(vm.viewState(hasEntries: true) == .populated)
    }

    // MARK: - Copy as Markdown

    @Test func copyMarkdownWithTitle() {
        let vm = HistoryViewModel(metadataService: MockLinkMetadataService())
        let entry = HistoryEntry(
            input: "https://example.com?utm_source=tw",
            output: "https://example.com",
            pageTitle: "Example Site"
        )

        vm.copyMarkdown(for: entry)

        #expect(UIPasteboard.general.string == "[Example Site](https://example.com)")
        #expect(vm.copiedEntryID == entry.id)
    }

    @Test func copyMarkdownWithoutTitle() {
        let vm = HistoryViewModel(metadataService: MockLinkMetadataService())
        let entry = HistoryEntry(
            input: "https://example.com?utm_source=tw",
            output: "https://example.com"
        )

        vm.copyMarkdown(for: entry)

        #expect(UIPasteboard.general.string == "[https://example.com](https://example.com)")
        #expect(vm.copiedEntryID == entry.id)
    }

    @Test func copyMarkdownEscapesBracketsInTitle() {
        let vm = HistoryViewModel(metadataService: MockLinkMetadataService())
        let entry = HistoryEntry(
            input: "https://example.com?ref=home",
            output: "https://example.com",
            pageTitle: "Title [with] brackets"
        )

        vm.copyMarkdown(for: entry)

        #expect(UIPasteboard.general.string == "[Title \\[with\\] brackets](https://example.com)")
        #expect(vm.copiedEntryID == entry.id)
    }
}
