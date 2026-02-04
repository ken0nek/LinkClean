//
//  CleanedURL.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation

struct CleanedURL: Identifiable, Equatable {
    let id: UUID
    let input: String
    let output: String

    init(id: UUID = UUID(), input: String, output: String) {
        self.id = id
        self.input = input
        self.output = output
    }
}
