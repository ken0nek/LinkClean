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
}
