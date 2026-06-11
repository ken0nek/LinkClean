//
//  CleanSessionTests.swift
//  LinkCleanCoreTests
//

import Testing
import Foundation
@testable import LinkCleanCore

struct CleanSessionTests {

    /// Minimal outcome for ledger tests — only `input`/`cleaned` matter here.
    private func outcome(input: String, cleaned: String) -> CleanOutcome {
        CleanOutcome(
            input: input,
            cleaned: cleaned,
            telemetry: .init(changed: input != cleaned, removedCount: 0, leftoverCount: 0, removedKindIDs: [], referenceMatches: [], domain: "x.com"),
            display: .init(removedNames: [], leftoverNames: [])
        )
    }

    // MARK: - Cleaned signal (once per distinct input)

    @Test func cleanedSignalFiresOncePerDistinctInput() {
        var session = CleanSession()
        #expect(session.setOutcome(outcome(input: "a", cleaned: "a1")) == true)
        // Re-clean of the same input (tab return / re-focus) is suppressed.
        #expect(session.setOutcome(outcome(input: "a", cleaned: "a1")) == false)
        // A genuinely new input signals again.
        #expect(session.setOutcome(outcome(input: "b", cleaned: "b1")) == true)
    }

    @Test func refineSuppressesCleanedSignalButReArmsExports() {
        var session = CleanSession()
        #expect(session.setOutcome(outcome(input: "a", cleaned: "a-dirty")) == true)
        #expect(session.noteCopy(saveHistoryEnabled: true).signalExport == true)

        // A leftover-pill refine: same input, cleaner output.
        #expect(session.setOutcome(outcome(input: "a", cleaned: "a-clean")) == false) // no cleaned re-signal
        #expect(session.noteCopy(saveHistoryEnabled: true).signalExport == true)       // but export re-arms
    }

    @Test func nilOutcomeNeverSignals() {
        var session = CleanSession()
        #expect(session.setOutcome(nil) == false)
        #expect(session.outcome == nil)
    }

    // MARK: - Export dedup (copy / share independent, per output)

    @Test func copyDedupesPerDistinctOutput() {
        var session = CleanSession()
        session.setOutcome(outcome(input: "a", cleaned: "out"))
        #expect(session.noteCopy(saveHistoryEnabled: false).signalExport == true)
        #expect(session.noteCopy(saveHistoryEnabled: false).signalExport == false) // repeat tap
    }

    @Test func copyAndShareDedupeIndependently() {
        var session = CleanSession()
        session.setOutcome(outcome(input: "a", cleaned: "out"))
        // Copy and share are distinct exports of the same output — both fire once.
        #expect(session.noteCopy(saveHistoryEnabled: false).signalExport == true)
        #expect(session.noteShare(saveHistoryEnabled: false).signalExport == true)
        // ...and each dedupes on repeat.
        #expect(session.noteCopy(saveHistoryEnabled: false).signalExport == false)
        #expect(session.noteShare(saveHistoryEnabled: false).signalExport == false)
    }

    @Test func exportSignalsAgainAfterOutputChanges() {
        var session = CleanSession()
        session.setOutcome(outcome(input: "a", cleaned: "out1"))
        #expect(session.noteCopy(saveHistoryEnabled: false).signalExport == true)
        session.setOutcome(outcome(input: "b", cleaned: "out2"))
        #expect(session.noteCopy(saveHistoryEnabled: false).signalExport == true)
    }

    // MARK: - History (shared key; consumed only when enabled)

    @Test func copyThenShareWriteOneHistoryRow() {
        var session = CleanSession()
        session.setOutcome(outcome(input: "a", cleaned: "out"))
        #expect(session.noteCopy(saveHistoryEnabled: true).recordHistory == true)  // first export records
        #expect(session.noteShare(saveHistoryEnabled: true).recordHistory == false) // same output, no second row
    }

    @Test func historyKeyNotConsumedWhileDisabled() {
        var session = CleanSession()
        session.setOutcome(outcome(input: "a", cleaned: "out"))
        // Copied while history is off: no row, and the history key is not consumed...
        #expect(session.noteCopy(saveHistoryEnabled: false).recordHistory == false)
        // ...so sharing the same output with history re-enabled still records it
        // (a different export type, so it isn't deduped as a repeat).
        #expect(session.noteShare(saveHistoryEnabled: true).recordHistory == true)
    }

    // MARK: - Review counting (shared; survives clear-then-repaste)

    @Test func reviewCountsOncePerDistinctOutputAcrossCopyAndShare() {
        var session = CleanSession()
        session.setOutcome(outcome(input: "a", cleaned: "out"))
        #expect(session.noteCopy(saveHistoryEnabled: false).countForReview == true)
        #expect(session.noteShare(saveHistoryEnabled: false).countForReview == false) // same output
    }

    @Test func clearThenRepasteDoesNotReCountReviewButResetsOtherKeys() {
        var session = CleanSession()
        session.setOutcome(outcome(input: "https://x.com", cleaned: "out"))
        let first = session.noteCopy(saveHistoryEnabled: true)
        #expect(first.countForReview == true)
        #expect(first.signalExport == true)

        // Clear the input...
        session.beginInput("")
        // ...then re-paste the same URL producing the same output.
        #expect(session.setOutcome(outcome(input: "https://x.com", cleaned: "out")) == true) // cleaned key reset → re-signals
        let second = session.noteCopy(saveHistoryEnabled: true)
        #expect(second.signalExport == true)        // copy key reset → exports again
        #expect(second.recordHistory == true)       // history key reset → records again
        #expect(second.countForReview == false)     // review key NOT reset → no double count
    }

    @Test func nonEmptyInputChangeDoesNotResetKeys() {
        var session = CleanSession()
        session.setOutcome(outcome(input: "a", cleaned: "out"))
        session.noteCopy(saveHistoryEnabled: false)
        // A non-empty edit must NOT reset the ledger (only an empty input does).
        session.beginInput("ab")
        session.setOutcome(outcome(input: "a", cleaned: "out")) // same output still deduped
        #expect(session.noteCopy(saveHistoryEnabled: false).signalExport == false)
    }

    @Test func noEffectsForEmptyOutput() {
        var session = CleanSession()
        session.setOutcome(nil)
        let effects = session.noteCopy(saveHistoryEnabled: true)
        #expect(effects == .init(signalExport: false, recordHistory: false, countForReview: false))
    }
}
