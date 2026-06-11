//
//  AppGroup.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation

public nonisolated enum AppGroup {
    public static let identifier = "group.com.ken0nek.LinkClean"

    /// The cross-process settings suite shared by the app and the action
    /// extensions. `nil` only if the App Group is misconfigured. Centralizes the
    /// suite lookup that ``DefaultReviewService`` and other shared-state readers
    /// default to.
    public static var userDefaults: UserDefaults? { UserDefaults(suiteName: identifier) }
}
