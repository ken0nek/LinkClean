//
//  HistoryView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import LinkCleanCommon
import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \HistoryEntry.createdAt, order: .reverse) private var entries: [HistoryEntry]

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No History",
                    systemImage: "clock",
                    description: Text("Cleaned URLs you copy will appear here.")
                )
            } else {
                List(entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.output)
                            .font(.body)
                            .foregroundStyle(.tint)
                            .lineLimit(1)

                        Text(entry.input)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(entry.createdAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .screenBackground()
        .navigationTitle("History")
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .modelContainer(HistoryContainer.makeInMemory())
    }
}
