//
//  ContentView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/1/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label { Text(.tabHome) } icon: { Image(systemName: "house") }
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label { Text(.tabHistory) } icon: { Image(systemName: "clock") }
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label { Text(.tabSettings) } icon: { Image(systemName: "gearshape") }
            }
        }
    }
}

#Preview {
    ContentView()
}
