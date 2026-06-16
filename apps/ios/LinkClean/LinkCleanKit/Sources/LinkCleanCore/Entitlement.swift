//
//  Entitlement.swift
//  LinkCleanKit
//
//  Created by Gemini CLI on 6/9/26.
//

import Foundation

/// The tiers of functionality available in LinkClean.
///
/// Use `Entitlement.pro` to gate premium features. Missing or unknown values
/// must always resolve to `.free` (fail-closed) to ensure data integrity
/// across different versions of the app and extensions.
public enum Entitlement: String, Sendable {
    /// The default free tier.
    case free

    /// The "LinkClean Pro" tier, providing full access to all features.
    case pro
}
