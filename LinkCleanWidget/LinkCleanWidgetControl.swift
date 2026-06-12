//
//  LinkCleanWidgetControl.swift
//  LinkCleanWidget
//
//  Created by Ken Tominaga on 6/12/26.
//

import AppIntents
import SwiftUI
import WidgetKit
import LinkCleanIntents

/// A Control Center / Lock Screen control that cleans the link on the clipboard
/// in one tap — the killer flow (copy a link anywhere, tap the control, the
/// cleaned link replaces it). A `StaticControlConfiguration` button (no user
/// configuration); configurable controls are the deferred Pro tier. The button
/// runs ``CleanClipboardIntent`` in this extension's process, which is why the
/// target needs the App Group (to read the user's rules/settings).
struct LinkCleanWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.ken0nek.LinkClean.CleanClipboardControl") {
            ControlWidgetButton(action: CleanClipboardIntent()) {
                Label("Clean Clipboard", systemImage: "link")
            }
        }
        .displayName("Clean Clipboard")
        .description("Remove tracking from the link on your clipboard.")
    }
}
