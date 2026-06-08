//
//  URLCleaner.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/1/26.
//

import Foundation

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
        guard var components = URLComponents(string: urlString) else {
            return urlString
        }

        guard let queryItems = components.queryItems, !queryItems.isEmpty else {
            return urlString
        }

        let normalized = Set(parameters.map { $0.lowercased() })
        let filtered = queryItems.filter { item in
            !normalized.contains(item.name.lowercased())
        }

        components.queryItems = filtered.isEmpty ? nil : filtered

        return components.string ?? urlString
    }

    public static func clean(_ url: URL) -> URL {
        clean(url, removing: TrackingParameterCatalog.defaultEnabledSet)
    }

    public static func clean(_ url: URL, removing parameters: Set<String>) -> URL {
        let cleaned = clean(url.absoluteString, removing: parameters)
        return URL(string: cleaned) ?? url
    }

    /// Number of query parameters removed between an original and a cleaned URL
    /// string — drives the `removedCount` analytics bucket. Compares item
    /// counts only; never inspects parameter names or values.
    public static func removedParameterCount(from original: String, to cleaned: String) -> Int {
        let before = URLComponents(string: original)?.queryItems?.count ?? 0
        let after = URLComponents(string: cleaned)?.queryItems?.count ?? 0
        return max(0, before - after)
    }
}
