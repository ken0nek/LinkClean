//
//  URLCleaningService.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation
import LinkCleanCommon

protocol URLCleaningService: Sendable {
    func isValidURL(_ input: String) -> Bool
    func clean(_ input: String) async throws -> CleanedURL?
}

struct DefaultURLCleaningService: URLCleaningService {
    func isValidURL(_ input: String) -> Bool {
        URLCleaner.isValidURL(input)
    }

    func clean(_ input: String) async throws -> CleanedURL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        guard isValidURL(trimmed) else {
            return nil
        }

        let output = URLCleaner.clean(trimmed)
        return CleanedURL(input: trimmed, output: output)
    }
}
