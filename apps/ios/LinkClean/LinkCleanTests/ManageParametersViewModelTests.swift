//
//  ManageParametersViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
@testable import LinkClean
import LinkCleanCore
import LinkCleanData

@MainActor
struct ManageParametersViewModelTests {

    private func makeSUT() -> (ManageParametersViewModel, TrackingParameterStore, String) {
        let suiteName = "LinkCleanTests.manage.\(UUID().uuidString)"
        let store = TrackingParameterStore(suiteName: suiteName)
        let vm = ManageParametersViewModel(store: store)
        return (vm, store, suiteName)
    }

    @Test func isEnabledDefaultsToTrue() {
        let (vm, _, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        #expect(vm.isEnabled("utm_source") == true)
    }

    @Test func isEnabledIsCaseInsensitive() {
        let (vm, _, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        #expect(vm.isEnabled("UTM_SOURCE") == true)
    }

    @Test func setEnabledDisables() {
        let (vm, _, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.setEnabled("utm_source", isEnabled: false)

        #expect(vm.isEnabled("utm_source") == false)
    }

    @Test func setEnabledReenables() {
        let (vm, _, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.setEnabled("utm_source", isEnabled: false)
        vm.setEnabled("utm_source", isEnabled: true)

        #expect(vm.isEnabled("utm_source") == true)
    }

    @Test func onAppearReloadsFromStore() {
        let (vm, store, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        store.setEnabled("utm_source", isEnabled: false)
        vm.onAppear()

        #expect(vm.isEnabled("utm_source") == false)
    }

    @Test func setEnabledEmitsDefaultToggledWithBuiltInName() {
        let suiteName = "LinkCleanTests.manage.\(UUID().uuidString)"
        let spy = SpyAnalytics()
        let vm = ManageParametersViewModel(store: TrackingParameterStore(suiteName: suiteName), analytics: spy)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.setEnabled("UTM_Source", isEnabled: false)

        #expect(spy.events == [.parametersDefaultToggled(parameter: "utm_source", enabled: false)])
    }

    // MARK: - Search

    private func names(in sections: [TrackingParameterSection]) -> [String] {
        sections.flatMap { $0.parameters.map(\.name) }
    }

    @Test func filteredSectionsReturnsAllSectionsWhenSearchEmpty() {
        let (vm, _, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        #expect(vm.filteredSections == vm.sections)
    }

    @Test func filteredSectionsMatchesParameterName() {
        let (vm, _, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.searchText = "fbclid"
        let matched = names(in: vm.filteredSections)
        #expect(matched.contains("fbclid"))
        #expect(!matched.contains("utm_source"))
    }

    @Test func filteredSectionsIsCaseAndDiacriticInsensitive() {
        let (vm, _, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.searchText = "FBCLID"
        #expect(names(in: vm.filteredSections).contains("fbclid"))
    }

    @Test func filteredSectionsMatchesHostScope() {
        let (vm, _, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        // `si`/`feature` are host-scoped to youtube.com; searching the host name
        // surfaces them even though the parameter name doesn't contain "youtube".
        vm.searchText = "youtube"
        let matched = names(in: vm.filteredSections)
        #expect(matched.contains("si"))
        #expect(matched.contains("feature"))
    }

    @Test func filteredSectionsDropsEmptySections() {
        let (vm, _, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.searchText = "fbclid"
        // Only sections that still contain a match survive.
        #expect(vm.filteredSections.allSatisfy { !$0.parameters.isEmpty })
        #expect(vm.filteredSections.count == 1)
    }

    @Test func filteredSectionsIsEmptyWhenNoMatch() {
        let (vm, _, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.searchText = "zzz-no-such-parameter-zzz"
        #expect(vm.filteredSections.isEmpty)
    }
}
