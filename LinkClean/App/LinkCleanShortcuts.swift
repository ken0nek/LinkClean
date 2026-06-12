//
//  LinkCleanShortcuts.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/12/26.
//

import AppIntents
import LinkCleanIntents

/// Exposes LinkClean's App Intents to Siri, Spotlight, and the Action button
/// with spoken phrases (S1). One `AppShortcutsProvider` per app target; the
/// system discovers it automatically — there is no registration call. Every
/// phrase must include `\(.applicationName)`, which the framework requires.
struct LinkCleanShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CleanClipboardIntent(),
            phrases: [
                "Clean my clipboard with \(.applicationName)",
                "Clean my link with \(.applicationName)",
                "Clean the link on my clipboard with \(.applicationName)"
            ],
            shortTitle: "Clean Clipboard",
            systemImageName: "doc.on.clipboard"
        )
        AppShortcut(
            intent: CleanLinkIntent(),
            phrases: [
                "Clean a link with \(.applicationName)"
            ],
            shortTitle: "Clean Link",
            systemImageName: "link"
        )
    }
}
