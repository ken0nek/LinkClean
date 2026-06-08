//
//  ContentView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/1/26.
//

import LinkCleanKit
import SwiftUI

struct ContentView: View {
    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabs
            } else {
                // Swap onboarding in at the root (not as a cover over the tabs)
                // so HomeView never mounts during onboarding — its auto-paste
                // would otherwise trigger the iOS paste-permission banner.
                OnboardingView(onFinished: { hasCompletedOnboarding = true })
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }

    private var mainTabs: some View {
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
