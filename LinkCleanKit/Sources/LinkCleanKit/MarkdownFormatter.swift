//
//  MarkdownFormatter.swift
//  LinkCleanKit
//

import Foundation

public nonisolated enum MarkdownFormatter {
    public static func markdownLink(title: String?, url: String) -> String {
        let linkText = (title ?? url)
            .replacingOccurrences(of: "[", with: "\\[")
            .replacingOccurrences(of: "]", with: "\\]")
        let safeURL = url
            .replacingOccurrences(of: "(", with: "%28")
            .replacingOccurrences(of: ")", with: "%29")
        return "[\(linkText)](\(safeURL))"
    }
}
