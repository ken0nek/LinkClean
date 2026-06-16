//
//  StubParameterAdvisor.swift
//  LinkCleanTests
//

import Foundation
@testable import LinkClean
import LinkCleanCore

/// A configurable ``ParameterAdvising`` double: returns a canned suggestion (or
/// `nil`) and records the candidate lists it was asked about, so tests can both
/// drive the Home suggestion flow and assert what reached the advisor (e.g. that
/// managed catalog defaults were filtered out before it ran).
@MainActor
struct StubParameterAdvisor: ParameterAdvising {
    final class Recorder {
        var callCount = 0
        var candidates: [[String]] = []
    }

    var modelAvailable = true
    var result: ParameterSuggestion?
    let recorder = Recorder()

    var isModelAvailable: Bool { modelAvailable }
    func prewarm() {}

    func suggestion(among candidates: [String]) async -> ParameterSuggestion? {
        recorder.callCount += 1
        recorder.candidates.append(candidates)
        return result
    }
}
