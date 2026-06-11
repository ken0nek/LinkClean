//
//  CustomParametersViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
@testable import LinkClean
import LinkCleanCore
import LinkCleanData

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

    @Test func addEmitsCustomAddedWithRunningTotal() {
        let suiteName = "LinkCleanTests.custom.\(UUID().uuidString)"
        let spy = SpyAnalytics()
        let vm = CustomParametersViewModel(store: TrackingParameterStore(suiteName: suiteName), analytics: spy)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.newParameter = "alpha"
        _ = vm.addParameter()
        vm.newParameter = "beta"
        _ = vm.addParameter()

        #expect(spy.events == [
            .parametersCustomAdded(totalCount: 1),
            .parametersCustomAdded(totalCount: 2),
        ])
    }

    @Test func deleteEmitsCustomDeletedWithRunningTotal() {
        let suiteName = "LinkCleanTests.custom.\(UUID().uuidString)"
        let spy = SpyAnalytics()
        let vm = CustomParametersViewModel(store: TrackingParameterStore(suiteName: suiteName), analytics: spy)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.newParameter = "alpha"
        _ = vm.addParameter()
        spy.reset()

        vm.removeParameter("alpha")

        #expect(spy.events == [.parametersCustomDeleted(totalCount: 0)])
    }

    @Test func onAppearSignalsScreenShown() {
        let suiteName = "LinkCleanTests.custom.\(UUID().uuidString)"
        let spy = SpyAnalytics()
        let vm = CustomParametersViewModel(store: TrackingParameterStore(suiteName: suiteName), analytics: spy)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.onAppear()

        #expect(spy.events == [.parametersCustomShown])
    }

    @Test func rejectedAddEmitsNothing() {
        let suiteName = "LinkCleanTests.custom.\(UUID().uuidString)"
        let spy = SpyAnalytics()
        let vm = CustomParametersViewModel(store: TrackingParameterStore(suiteName: suiteName), analytics: spy)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        vm.newParameter = "utm_source" // already a default
        _ = vm.addParameter()

        #expect(spy.events.isEmpty)
    }

    // MARK: - Add gate (T3)

    @Test func isAtFreeLimitReflectsEntitlementAndCount() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        // No rules yet: neither tier is limited.
        #expect(vm.isAtFreeLimit(entitlement: .free) == false)
        #expect(vm.isAtFreeLimit(entitlement: .pro) == false)

        vm.newParameter = "alpha"
        _ = vm.addParameter() // consumes the one free rule

        #expect(vm.isAtFreeLimit(entitlement: .free) == true)
        #expect(vm.isAtFreeLimit(entitlement: .pro) == false) // Pro is never limited
    }

    @Test func requestAddParameterAddsWhenAllowed() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        vm.newParameter = "alpha"

        let result = vm.requestAddParameter(entitlement: .free)

        #expect(result == .attempted(error: nil))
        #expect(vm.customParameters.contains("alpha"))
    }

    @Test func requestAddParameterGatesFreeUserAtLimit() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        vm.newParameter = "alpha"
        _ = vm.addParameter() // consumes the one free rule

        vm.newParameter = "beta"
        let result = vm.requestAddParameter(entitlement: .free)

        #expect(result == .gated(.customParamSettings))
        #expect(!vm.customParameters.contains("beta")) // nothing added while gated
    }

    @Test func requestAddParameterSurfacesValidationError() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        vm.newParameter = "utm_source" // already a default catalog param

        let result = vm.requestAddParameter(entitlement: .free)

        #expect(result == .attempted(error: "Already in default parameters."))
    }

    @Test func requestAddParameterNeverGatesPro() {
        let (vm, suiteName) = makeSUT()
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        vm.newParameter = "a"
        _ = vm.addParameter()
        vm.newParameter = "b"
        _ = vm.addParameter() // two rules — well past the free allowance

        vm.newParameter = "c"
        let result = vm.requestAddParameter(entitlement: .pro)

        #expect(result == .attempted(error: nil))
        #expect(vm.customParameters.contains("c"))
    }
}
