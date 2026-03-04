//
//  HistoryContainer.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation
import SwiftData

public enum HistoryContainer {
    public static func makeShared() -> ModelContainer? {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroup.identifier
        ) else {
            return nil
        }

        let storeURL = groupURL.appendingPathComponent("HistoryStore.sqlite")
        let configuration = ModelConfiguration(url: storeURL)

        return try? ModelContainer(for: HistoryEntry.self, configurations: configuration)
    }

    public static func makeInMemory() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        // Safe: in-memory ModelConfiguration has no persistent store and cannot fail to initialise.
        return try! ModelContainer(for: HistoryEntry.self, configurations: configuration)
    }
}
