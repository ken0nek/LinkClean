//
//  ContentView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/1/26.
//

import LinkCleanCore
import SwiftUI

struct ContentView: View {
    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @State private var selection: AppTab = .initial

    enum AppTab: Hashable {
        case home, history, settings

        /// Production launches always start on Home; DEBUG screenshot/testing
        /// builds can deep-link to a tab with `-tab-history` / `-tab-settings`.
        static var initial: AppTab {
            #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-tab-history") { return .history }
            if arguments.contains("-tab-settings") { return .settings }
            #endif
            return .home
        }
    }

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
        TabView(selection: $selection) {
            Tab(value: AppTab.home) {
                NavigationStack {
                    HomeView()
                }
            } label: {
                Label { Text(.tabHome) } icon: { Image(systemName: "house") }
            }

            Tab(value: AppTab.history) {
                NavigationStack {
                    HistoryView()
                }
            } label: {
                Label { Text(.tabHistory) } icon: { Image(systemName: "clock") }
            }

            Tab(value: AppTab.settings) {
                NavigationStack {
                    SettingsView()
                }
            } label: {
                Label { Text(.tabSettings) } icon: { Image(systemName: "gearshape") }
            }
        }
        // iOS 26: the tab bar recedes as the user scrolls into content (Home and
        // History are scroll views), then returns on scroll-up.
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
        .environment(EntitlementsModel.preview)
}
