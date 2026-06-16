//
//  LinkCleanWidget.swift
//  LinkCleanWidget
//
//  Created by Ken Tominaga on 6/12/26.
//

import WidgetKit
import SwiftUI
import AppIntents
import LinkCleanIntents

/// A single static entry — the widget shows a fixed "Clean Clipboard" button and
/// never needs a real timeline.
struct CleanClipboardEntry: TimelineEntry {
    let date: Date
}

struct CleanClipboardProvider: TimelineProvider {
    func placeholder(in context: Context) -> CleanClipboardEntry {
        CleanClipboardEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (CleanClipboardEntry) -> Void) {
        completion(CleanClipboardEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CleanClipboardEntry>) -> Void) {
        // Static content: one entry, never reloaded on a schedule.
        completion(Timeline(entries: [CleanClipboardEntry(date: Date())], policy: .never))
    }
}

struct LinkCleanWidgetEntryView: View {
    var body: some View {
        // The whole tile is the tap target (`.plain`, not a filled pill), with the
        // brand teal tint instead of the widget's default-blue accent.
        Button(intent: CleanClipboardIntent()) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: "link")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
                Spacer(minLength: 6)
                Text("Clean")
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                Text("Clipboard")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .tint(.teal)
    }
}

/// A single-button Home/Lock Screen widget that cleans the clipboard (free, like
/// the control). `StaticConfiguration` — no user-configurable parameters; the
/// configurable variant is the deferred Pro tier.
struct LinkCleanWidget: Widget {
    let kind = "com.ken0nek.LinkClean.CleanClipboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CleanClipboardProvider()) { _ in
            LinkCleanWidgetEntryView()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Clean Clipboard")
        .description("Remove tracking from the link on your clipboard with one tap.")
        .supportedFamilies([.systemSmall])
    }
}
