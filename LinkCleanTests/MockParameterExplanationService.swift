//
//  MockParameterExplanationService.swift
//  LinkCleanTests
//

import Foundation
@testable import LinkClean

@MainActor
struct MockParameterExplanationService: ParameterExplanationService {
    /// Records calls so tests can assert the cache prevents re-fetching. A class so
    /// the value-type mock's copies (the view model keeps its own) share one count.
    final class Recorder {
        var callCount = 0
        var parameters: [String] = []
    }

    var available = true
    var result: ParameterExplanation? = ParameterExplanation(
        oneLiner: "Identifies the click that brought you here.",
        isTracking: true
    )
    let recorder = Recorder()

    var isAvailable: Bool { available }

    func explain(parameter: String) async -> ParameterExplanation? {
        recorder.callCount += 1
        recorder.parameters.append(parameter)
        return available ? result : nil
    }
}
