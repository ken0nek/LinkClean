//
//  CleanSession.swift
//  LinkCleanCore
//
//  Created by Ken Tominaga on 6/11/26.
//

import Foundation

/// The dedup ledger for one Home session: input → outcome → exports. It owns the
/// five keys whose pairwise-different reset rules used to live as field
/// interactions spread across HomeViewModel's `didSet` and handlers. Encoding the
/// ledger as a value type with intent methods turns "remember to also reset X
/// when Y" into an exhaustively testable transition function (fast macOS suite).
///
/// The invariants, made explicit:
/// - the cleaned signal fires once per distinct *input* (`setOutcome`)
/// - copy and share each dedup per distinct *output*, independently
/// - history and review-counting are shared across copy and share
/// - clearing the input resets every key **except** the review counter — a
///   clear-then-repaste of the same URL is the same realized value
/// - a leftover-pill refine (same input, cleaner output) re-arms exports but not
///   the cleaned signal
public struct CleanSession: Equatable, Sendable {
    /// The current cleaned outcome, or `nil` when the input is empty/invalid.
    public private(set) var outcome: CleanOutcome?

    private var lastSignaledCleanInput: String?
    private var lastCopiedOutput: String?
    private var lastSharedOutput: String?
    private var lastRecordedHistoryOutput: String?
    private var lastReviewCountedOutput: String?

    public init() {}

    /// Call when the input text changes. When the input becomes empty, the
    /// per-input and per-output dedup keys reset — except the review counter,
    /// which must survive a clear-then-repaste of the same URL so the same
    /// realized value can't count toward review eligibility twice.
    public mutating func beginInput(_ trimmedInput: String) {
        guard trimmedInput.isEmpty else { return }
        lastSignaledCleanInput = nil
        lastCopiedOutput = nil
        lastSharedOutput = nil
        lastRecordedHistoryOutput = nil
    }

    /// Records the freshly-cleaned outcome and returns whether the once-per-input
    /// `Home.URL.cleaned` signal should fire. Re-cleans of the same input (tab
    /// return, re-focus) and leftover-pill refines (same input, cleaner output)
    /// are suppressed — a refine still re-arms exports via its changed output.
    @discardableResult
    public mutating func setOutcome(_ outcome: CleanOutcome?) -> Bool {
        self.outcome = outcome
        guard let outcome, outcome.input != lastSignaledCleanInput else { return false }
        lastSignaledCleanInput = outcome.input
        return true
    }

    /// What an export fires, after deduping against this session's ledger.
    public struct ExportEffects: Equatable, Sendable {
        /// Emit `Home.URL.copied` / `Home.URL.shared` — deduped per distinct
        /// output, copy and share tracked separately (a user can do both).
        public let signalExport: Bool
        /// Write a history row — shared across copy and share, and only when
        /// history saving is enabled (so the key isn't consumed while disabled).
        public let recordHistory: Bool
        /// Count this output toward review eligibility — shared across copy and share.
        public let countForReview: Bool

        public init(signalExport: Bool, recordHistory: Bool, countForReview: Bool) {
            self.signalExport = signalExport
            self.recordHistory = recordHistory
            self.countForReview = countForReview
        }
    }

    /// Notes a copy of the current cleaned output.
    public mutating func noteCopy(saveHistoryEnabled: Bool) -> ExportEffects {
        note(isCopy: true, saveHistoryEnabled: saveHistoryEnabled)
    }

    /// Notes a share of the current cleaned output.
    public mutating func noteShare(saveHistoryEnabled: Bool) -> ExportEffects {
        note(isCopy: false, saveHistoryEnabled: saveHistoryEnabled)
    }

    private mutating func note(isCopy: Bool, saveHistoryEnabled: Bool) -> ExportEffects {
        let none = ExportEffects(signalExport: false, recordHistory: false, countForReview: false)
        guard let output = outcome?.cleaned, !output.isEmpty else { return none }

        // A repeat tap on the same output for this export type does nothing at all
        // — and crucially consumes none of the shared (history/review) keys, so a
        // deduped copy can't pre-empt a later share of the same output.
        let isNewExport = isCopy ? output != lastCopiedOutput : output != lastSharedOutput
        guard isNewExport else { return none }
        if isCopy { lastCopiedOutput = output } else { lastSharedOutput = output }

        // History key consumed only when we'd actually record, so re-enabling
        // history later still writes a row for an output exported while it was off.
        let recordHistory = saveHistoryEnabled && output != lastRecordedHistoryOutput
        if recordHistory { lastRecordedHistoryOutput = output }

        let countForReview = output != lastReviewCountedOutput
        if countForReview { lastReviewCountedOutput = output }

        return ExportEffects(signalExport: true, recordHistory: recordHistory, countForReview: countForReview)
    }
}
