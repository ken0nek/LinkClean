//
//  CleanLinkStrategy.swift
//  LinkCleanExtensionUI
//
//  Created by Ken Tominaga on 6/11/26.
//

import Foundation
import LinkCleanCore

/// "Clean URL": extract a web URL, copy the cleaned URL to the pasteboard, emit
/// the clean-succeeded signal plus one reference-observed signal per catalog-gap
/// tracker left behind.
public struct CleanLinkStrategy: ActionOutputStrategy {
    public init() {}

    public var surface: String { "action" }

    public func extract(from items: [NSExtensionItem]) async -> ExtractedURL? {
        guard let url = await URLExtraction.firstWebURL(from: items) else { return nil }
        return ExtractedURL(url: url)
    }

    public func failureEvent(hasAttachments: Bool) -> AnalyticsEvent {
        .actionCleanFailed(reason: hasAttachments ? .invalidInput : .noURL)
    }

    public func result(for outcome: CleanOutcome, extracted: ExtractedURL) async -> StrategyResult {
        let cleaned = URL(string: outcome.cleaned) ?? extracted.url
        var events: [AnalyticsEvent] = [.actionCleanSucceeded(telemetry: outcome.telemetry)]
        // Tier 1 catalog-gap names ride after the success signal so the priority
        // event uses the scarce in-process network window first (analytics §8).
        for parameter in outcome.telemetry.referenceMatches {
            events.append(.parametersReferenceObserved(parameter: parameter))
        }
        return StrategyResult(payload: PasteboardPayload(.url(cleaned)), successEvents: events)
    }
}
