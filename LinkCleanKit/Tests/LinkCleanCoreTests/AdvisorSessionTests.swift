//
//  AdvisorSessionTests.swift
//  LinkCleanCoreTests
//

import Testing
@testable import LinkCleanCore

struct AdvisorSessionTests {

    private func suggestion(_ name: String, tier: AnalyticsEvent.AdvisorTier = .reference) -> ParameterSuggestion {
        ParameterSuggestion(name: name, reason: "r", tier: tier)
    }

    @Test func surfaceShowsThenClears() {
        var session = AdvisorSession()
        #expect(session.surface(suggestion("cmpid")) == true)
        #expect(session.suggestion?.name == "cmpid")
        #expect(session.surface(nil) == false)
        #expect(session.suggestion == nil)
    }

    @Test func acceptFiresOncePerEngagedInput() {
        // A gated card stays on screen and re-tappable; only the first tap counts.
        var session = AdvisorSession()
        session.surface(suggestion("cmpid"))
        #expect(session.noteAccept(input: "url") == true)
        #expect(session.noteAccept(input: "url") == false)
        #expect(session.noteAccept(input: "url") == false)
    }

    @Test func dismissFiresOnceAndClearsTheCard() {
        var session = AdvisorSession()
        session.surface(suggestion("cmpid"))
        #expect(session.noteDismiss(input: "url") == true)
        #expect(session.suggestion == nil)
    }

    @Test func acceptThenDismissCountsAsAcceptOnly() {
        // The audit fix: a gated accept followed by "Not now" is one accept, not
        // an accept plus a dismiss — so the accept-vs-dismiss ratio stays clean.
        var session = AdvisorSession()
        session.surface(suggestion("cmpid"))
        #expect(session.noteAccept(input: "url") == true)
        #expect(session.noteDismiss(input: "url") == false)
    }

    @Test func dismissedNameIsNoLongerACandidate() {
        var session = AdvisorSession()
        session.surface(suggestion("cmpid"))
        _ = session.noteDismiss(input: "url")
        #expect(session.candidates(from: ["cmpid", "foo"]) == ["foo"])
    }

    @Test func candidatesExcludeManagedCatalogDefaults() {
        // utm_source is in TrackingParameterCatalog.allNames (a catalog default,
        // owned by the Settings toggle); novelparam is not.
        let session = AdvisorSession()
        #expect(session.candidates(from: ["utm_source", "novelparam"]) == ["novelparam"])
    }

    @Test func keepsCurrentOnlyWhileItsNameSurvives() {
        var session = AdvisorSession()
        session.surface(suggestion("cmpid"))
        #expect(session.keepsCurrent(amongCandidates: ["cmpid", "foo"]) == true)
        #expect(session.keepsCurrent(amongCandidates: ["foo"]) == false)
    }

    @Test func beginInputResetsSuppressionButKeepsTheSuggestion() {
        var session = AdvisorSession()
        session.surface(suggestion("cmpid"))
        _ = session.noteAccept(input: "url")
        #expect(session.isEngaged(with: "url") == true)

        session.beginInput()
        #expect(session.isEngaged(with: "url") == false)   // engagement reset
        #expect(session.suggestion?.name == "cmpid")        // pick survives (anti-flicker)

        // A name dismissed before the edit is proposable again after it.
        var dismissedThenEdited = AdvisorSession()
        dismissedThenEdited.surface(suggestion("cmpid"))
        _ = dismissedThenEdited.noteDismiss(input: "url")
        #expect(dismissedThenEdited.candidates(from: ["cmpid"]) == [])
        dismissedThenEdited.beginInput()
        #expect(dismissedThenEdited.candidates(from: ["cmpid"]) == ["cmpid"])
    }
}
