//
//  HistoryRecorder.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation
import SwiftData

public enum HistoryRecorder {
    public static func save(input: String, output: String, in container: ModelContainer) throws {
        let context = ModelContext(container)
        let entry = HistoryEntry(input: input, output: output)
        context.insert(entry)
        try context.save()
    }
}
