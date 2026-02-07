//
//  MarkdownFormatter.swift
//  LinkCleanCommon
//

import Foundation

public nonisolated enum MarkdownFormatter {
    public static func markdownLink(title: String?, url: String) -> String {
        let linkText = (title ?? url)
            .replacingOccurrences(of: "[", with: "\\[")
            .replacingOccurrences(of: "]", with: "\\]")
        return "[\(linkText)](\(url))"
    }
}
