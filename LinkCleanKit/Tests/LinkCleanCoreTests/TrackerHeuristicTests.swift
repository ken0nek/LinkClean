//
//  TrackerHeuristicTests.swift
//  LinkCleanCoreTests
//

import Testing
@testable import LinkCleanCore

struct TrackerHeuristicTests {

    @Test func referenceCatalogNameIsKnownTracker() {
        // `epik` is a curated known tracker that is not in the default catalog,
        // so it lives in ReferenceParameterCatalog.names.
        #expect(TrackerHeuristic.assess("epik") == .likelyTracker(.known))
    }

    @Test func utmAndCampaignShapesAreCampaign() {
        #expect(TrackerHeuristic.assess("utm_source") == .likelyTracker(.campaign))
        #expect(TrackerHeuristic.assess("my_campaign") == .likelyTracker(.campaign))
    }

    @Test func clickIdentifierShapesAreClickID() {
        #expect(TrackerHeuristic.assess("gclid") == .likelyTracker(.clickID)) // *clid
        #expect(TrackerHeuristic.assess("fooclkid") == .likelyTracker(.clickID)) // *clkid
        #expect(TrackerHeuristic.assess("ad_click") == .likelyTracker(.clickID)) // *click*
    }

    @Test func affiliateShapesAreAffiliate() {
        #expect(TrackerHeuristic.assess("aff") == .likelyTracker(.affiliate))
        #expect(TrackerHeuristic.assess("aff_id") == .likelyTracker(.affiliate))
        #expect(TrackerHeuristic.assess("affiliate_token") == .likelyTracker(.affiliate))
    }

    @Test func trackSubstringIsGeneric() {
        #expect(TrackerHeuristic.assess("trackingcode") == .likelyTracker(.generic))
    }

    @Test func famouslyFunctionalNamesAreNeverSuggested() {
        for name in ["q", "id", "page", "v", "t", "lang", "search", "token", "sort", "type"] {
            #expect(TrackerHeuristic.assess(name) == .functional, "\(name) should be functional")
        }
    }

    @Test func bareMediaWordsAreFunctionalButCompoundShapesStillMatch() {
        // The bare functional words are excused from the substring rules...
        #expect(TrackerHeuristic.assess("track") == .functional) // music/podcast track #
        #expect(TrackerHeuristic.assess("click") == .functional) // image-map coordinate
        // ...but the compound tracker shapes that contain them still match.
        #expect(TrackerHeuristic.assess("trackid") == .likelyTracker(.generic))
        #expect(TrackerHeuristic.assess("ad_click") == .likelyTracker(.clickID))
    }

    @Test func unrecognizedNamesDeferToTheModel() {
        #expect(TrackerHeuristic.assess("xyzzy") == .unknown)
        #expect(TrackerHeuristic.assess("wpref") == .unknown)
    }

    @Test func assessmentIsCaseInsensitive() {
        #expect(TrackerHeuristic.assess("UTM_Source") == .likelyTracker(.campaign))
        #expect(TrackerHeuristic.assess("GCLID") == .likelyTracker(.clickID))
    }

    @Test func emptyNameIsUnknown() {
        #expect(TrackerHeuristic.assess("") == .unknown)
        #expect(TrackerHeuristic.assess("   ".trimmingCharacters(in: .whitespaces)) == .unknown)
    }
}
