//
//  ContentView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/1/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text("LinkClean")
                    .font(.largeTitle.bold())

                Text("Remove tracking parameters from URLs.")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Open Safari or any app with a link", systemImage: "1.circle")
                    Label("Tap the Share button", systemImage: "2.circle")
                    Label("Select \"Clean URL\"", systemImage: "3.circle")
                    Label("The cleaned URL is copied to your clipboard", systemImage: "4.circle")
                }
                .font(.body)
                .padding()
                .background(.fill.tertiary, in: .rect(cornerRadius: 12))
            }
            .padding()
            .navigationTitle("How to Use")
        }
    }
}

#Preview {
    ContentView()
}
