//
//  CustomParametersViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
@testable import LinkClean
import LinkCleanKit

@MainActor
struct CustomParametersViewModelTests {

    private func makeSUT() -> (CustomParametersViewModel, String) {
        let suiteName = "LinkCleanTests.custom.\(UUID().uuidString)"
        let vm = CustomParametersViewModel(store: TrackingParameterStore(suiteName: suiteName))
        return (vm, suiteName)
    }

    @Test func canAddIsFalseWhenEmpty() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.newParameter = ""
        #expect(vm.canAdd == false)
    }

    @Test func canAddIsFalseWhenWhitespace() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.newParameter = "   "
        #expect(vm.canAdd == false)
    }

    @Test func canAddIsTrueWithContent() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.newParameter = "custom_param"
        #expect(vm.canAdd == true)
    }

    @Test func addSucceedsAndClearsInput() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.newParameter = "my_param"
        let error = vm.addParameter()

        #expect(error == nil)
        #expect(vm.newParameter == "")
        #expect(vm.customParameters.contains("my_param"))
    }

    @Test func addNormalizesInput() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.newParameter = "  MY_Param  "
        _ = vm.addParameter()

        #expect(vm.customParameters.contains("my_param"))
    }

    @Test func addRejectsDuplicate() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.newParameter = "dupe"
        _ = vm.addParameter()

        vm.newParameter = "dupe"
        let error = vm.addParameter()

        #expect(error == "Already in custom parameters.")
    }

    @Test func addRejectsDefaultCatalogParam() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.newParameter = "utm_source"
        let error = vm.addParameter()

        #expect(error == "Already in default parameters.")
    }

    @Test func deleteByIndexSet() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.newParameter = "alpha"
        _ = vm.addParameter()
        vm.newParameter = "beta"
        _ = vm.addParameter()

        let index = vm.customParameters.firstIndex(of: "alpha")!
        vm.deleteParameters(at: IndexSet(integer: index))

        #expect(!vm.customParameters.contains("alpha"))
        #expect(vm.customParameters.contains("beta"))
    }

    @Test func removeByName() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.newParameter = "removeme"
        _ = vm.addParameter()

        vm.removeParameter("removeme")

        #expect(!vm.customParameters.contains("removeme"))
    }
}
