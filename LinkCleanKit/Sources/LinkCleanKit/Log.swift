//
//  Log.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/9/26.
//

import OSLog

public nonisolated enum Log {
    public static let app    = Logger(subsystem: "com.ken0nek.LinkClean", category: "App")
    public static let action = Logger(subsystem: "com.ken0nek.LinkClean", category: "Action")
}
