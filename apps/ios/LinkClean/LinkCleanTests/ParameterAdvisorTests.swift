//
//  ParameterAdvisorTests.swift
//  LinkCleanTests
//

import Testing
@testable import LinkClean
import LinkCleanCore

/// Exercises the production ``FoundationModelsParameterAdvisor`` deterministic
/// tier — the path that runs on every device, model or not. The model tier is
/// not asserted here: CI/simulator hardware has no Apple Intelligence, and the
/// live model must never be asserted against (it's non-deterministic).
@MainActor
struct ParameterAdvisorTests {

    private let advisor = FoundationModelsParameterAdvisor()

    @Test func referenceCatalogLeftoverSuggestsAtReferenceTier() async {
        let suggestion = await advisor.suggestion(among: ["epik"])
        #expect(suggestion?.name == "epik")
        #expect(suggestion?.tier == .reference)
        #expect(suggestion.map { !$0.reason.isEmpty } == true)
    }

    @Test func nameShapeLeftoverSuggestsAtHeuristicTier() async {
        // utm_source survives in the mock leftovers here only to prove the shape
        // rule fires deterministically with the heuristic tier and a reason.
        let suggestion = await advisor.suggestion(among: ["utm_campaign"])
        #expect(suggestion?.name == "utm_campaign")
        #expect(suggestion?.tier == .heuristic)
        #expect(suggestion.map { !$0.reason.isEmpty } == true)
    }

    @Test func functionalOnlyLeftoversProduceNoDeterministicSuggestion() async {
        // `q`/`id` are denylisted; with no model on the test host, nothing surfaces.
        let suggestion = await advisor.suggestion(among: ["q", "id"])
        #expect(suggestion == nil)
    }

    @Test func deterministicMatchWinsOverEarlierFunctionalCandidates() async {
        // The first tracker-shaped name wins even when functional keys precede it.
        let suggestion = await advisor.suggestion(among: ["q", "page", "epik"])
        #expect(suggestion?.name == "epik")
        #expect(suggestion?.tier == .reference)
    }
}
