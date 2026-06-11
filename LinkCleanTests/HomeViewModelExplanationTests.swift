//
//  HomeViewModelExplanationTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
@testable import LinkClean

@MainActor
struct HomeViewModelExplanationTests {

    private func makeViewModel(
        _ explanation: MockParameterExplanationService
    ) -> HomeViewModel {
        HomeViewModel(service: MockURLCleaningService(), explanationService: explanation)
    }

    @Test func skipsGenerationWhenModelUnavailable() async {
        var mock = MockParameterExplanationService()
        mock.available = false
        let vm = makeViewModel(mock)

        await vm.prepareExplanation(for: "fbclid")

        #expect(vm.isParameterExplanationAvailable == false)
        #expect(vm.explanation(for: "fbclid") == nil)
        #expect(mock.recorder.callCount == 0)
    }

    @Test func cachesOneLinerWhenAvailable() async {
        let mock = MockParameterExplanationService()
        let vm = makeViewModel(mock)

        await vm.prepareExplanation(for: "fbclid")

        #expect(vm.explanation(for: "fbclid") == "Identifies the click that brought you here.")
    }

    @Test func doesNotRefetchCachedParameter() async {
        let mock = MockParameterExplanationService()
        let vm = makeViewModel(mock)

        await vm.prepareExplanation(for: "fbclid")
        await vm.prepareExplanation(for: "fbclid")

        #expect(mock.recorder.callCount == 1)
    }

    @Test func explanationLookupIsCaseInsensitive() async {
        let mock = MockParameterExplanationService()
        let vm = makeViewModel(mock)

        await vm.prepareExplanation(for: "FBCLID")

        #expect(vm.explanation(for: "fbclid") != nil)
        #expect(vm.explanation(for: "FbClId") != nil)
    }

    @Test func clearsExplainingParameterAfterPreparing() async {
        let mock = MockParameterExplanationService()
        let vm = makeViewModel(mock)

        await vm.prepareExplanation(for: "fbclid")

        #expect(vm.explainingParameter == nil)
    }

    @Test func returnsNoExplanationWhenGenerationFails() async {
        var mock = MockParameterExplanationService()
        mock.result = nil       // model available, but produced nothing
        let vm = makeViewModel(mock)

        await vm.prepareExplanation(for: "weirdparam")

        #expect(vm.explanation(for: "weirdparam") == nil)
        #expect(mock.recorder.callCount == 1)   // it attempted generation
    }
}
