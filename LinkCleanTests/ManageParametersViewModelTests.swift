//
//  ManageParametersViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
@testable import LinkClean
import LinkCleanCommon

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
}
