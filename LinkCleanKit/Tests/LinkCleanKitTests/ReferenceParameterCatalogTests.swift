//
//  ReferenceParameterCatalogTests.swift
//  LinkCleanKitTests
//

import Testing
@testable import LinkCleanKit

struct ReferenceParameterCatalogTests {

    @Test func isDisjointFromTheDefaultCatalog() {
        // The invariant that makes a reference match mean "known tracker missing
        // from defaults": a name that is already a default could only survive
        // because the user disabled it — a different, already-tracked signal.
        #expect(ReferenceParameterCatalog.names.isDisjoint(with: TrackingParameterCatalog.defaultEnabledSet))
    }

    @Test func containsKnownTrackersNotInDefaults() {
        #expect(ReferenceParameterCatalog.names.contains("yclid"))
        #expect(ReferenceParameterCatalog.names.contains("gbraid"))
        #expect(ReferenceParameterCatalog.names.contains("mtm_source"))
        #expect(ReferenceParameterCatalog.names.contains("mkt_tok"))
    }

    @Test func allNamesAreLowercased() {
        #expect(ReferenceParameterCatalog.names.allSatisfy { $0 == $0.lowercased() })
    }

    @Test func isNotEmpty() {
        #expect(!ReferenceParameterCatalog.names.isEmpty)
    }
}
