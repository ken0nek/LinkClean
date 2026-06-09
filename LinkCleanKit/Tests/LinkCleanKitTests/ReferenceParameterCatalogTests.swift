//
//  ReferenceParameterCatalogTests.swift
//  LinkCleanKitTests
//

import Testing
@testable import LinkCleanKit

struct ReferenceParameterCatalogTests {

    @Test func isDisjointFromTheMainCatalog() {
        // The invariant that makes a reference match mean "known tracker missing
        // from the catalog": a name we already know about — enabled, shipped
        // off as too generic, or host-scoped — is a deliberate decision, not a
        // gap; toggles are already covered by `Parameters.Default.toggled`.
        #expect(ReferenceParameterCatalog.names.isDisjoint(with: TrackingParameterCatalog.allNames))
    }

    @Test func containsKnownTrackersNotInDefaults() {
        #expect(ReferenceParameterCatalog.names.contains("epik"))
        #expect(ReferenceParameterCatalog.names.contains("li_fat_id"))
        #expect(ReferenceParameterCatalog.names.contains("mtm_source"))
        #expect(ReferenceParameterCatalog.names.contains("hsa_acc"))
    }

    @Test func promotedTrackersGraduatedIntoTheMainCatalog() {
        // June 2026 promotion: unambiguous vendor click IDs moved from the
        // telemetry reference set into the removal defaults.
        let promoted = [
            "gbraid", "wbraid", "gad_source", "gad_campaignid", "srsltid",
            "yclid", "twclid", "ttclid", "_hsenc", "_hsmi", "mkt_tok",
        ]
        for name in promoted {
            #expect(!ReferenceParameterCatalog.names.contains(name), "\(name) should have left the reference set")
            #expect(TrackingParameterCatalog.allNames.contains(name), "\(name) should be a catalog default")
        }
    }

    @Test func allNamesAreLowercased() {
        #expect(ReferenceParameterCatalog.names.allSatisfy { $0 == $0.lowercased() })
    }

    @Test func isNotEmpty() {
        #expect(!ReferenceParameterCatalog.names.isEmpty)
    }
}
