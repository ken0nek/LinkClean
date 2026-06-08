//
//  URLCleaner.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/1/26.
//

import Foundation

/// The outcome of cleaning a URL: the cleaned string and how many tracking
/// parameters were removed. Lets callers (analytics) read the removed count
/// without re-parsing the URL — the count is derived from the same filter
/// `clean` applies, so the two can never disagree.
public nonisolated struct CleanResult: Sendable, Equatable {
    public let cleaned: String
    public let removedCount: Int

    /// Whether cleaning removed at least one tracking parameter.
    public var changed: Bool { removedCount > 0 }

    public init(cleaned: String, removedCount: Int) {
        self.cleaned = cleaned
        self.removedCount = removedCount
    }
}

public nonisolated enum URLCleaner {

    public static func isValidURL(_ urlString: String) -> Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host,
              !host.isEmpty
        else {
            return false
        }

        return true
    }

    /// URL-object counterpart of `isValidURL(_:)` so the app and the
    /// action extension share a single web-link policy.
    public static func isWebURL(_ url: URL) -> Bool {
        isValidURL(url.absoluteString)
    }

    public static func clean(_ urlString: String) -> String {
        clean(urlString, removing: TrackingParameterCatalog.defaultEnabledSet)
    }

    public static func clean(_ urlString: String, removing parameters: Set<String>) -> String {
        cleanResult(urlString, removing: parameters).cleaned
    }

    /// Cleans `urlString` and reports how many query parameters were removed, so
    /// callers don't have to re-parse the URL to count. The count and the
    /// cleaned string come from one pass over the same filter.
    public static func cleanResult(_ urlString: String, removing parameters: Set<String>) -> CleanResult {
        guard var components = URLComponents(string: urlString),
              let queryItems = components.queryItems, !queryItems.isEmpty
        else {
            return CleanResult(cleaned: urlString, removedCount: 0)
        }

        let normalized = Set(parameters.map { $0.lowercased() })
        let filtered = queryItems.filter { item in
            !normalized.contains(item.name.lowercased())
        }

        components.queryItems = filtered.isEmpty ? nil : filtered

        return CleanResult(cleaned: components.string ?? urlString, removedCount: queryItems.count - filtered.count)
    }

    public static func clean(_ url: URL) -> URL {
        clean(url, removing: TrackingParameterCatalog.defaultEnabledSet)
    }

    public static func clean(_ url: URL, removing parameters: Set<String>) -> URL {
        cleanResult(url, removing: parameters).cleaned
    }

    /// URL counterpart of `cleanResult(_:removing:)`: the cleaned URL plus the
    /// number of query parameters removed.
    public static func cleanResult(_ url: URL, removing parameters: Set<String>) -> (cleaned: URL, removedCount: Int) {
        let result = cleanResult(url.absoluteString, removing: parameters)
        return (URL(string: result.cleaned) ?? url, result.removedCount)
    }
}
