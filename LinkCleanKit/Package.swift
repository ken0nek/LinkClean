// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LinkCleanKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
        // The non-UIKit layers (Core/Data/Analytics) and their test suites build
        // and run on the Mac host — the fast lane: `swift test` runs the
        // LinkCleanCoreTests + LinkCleanDataTests suites in seconds, no simulator.
        // LinkCleanExtensionUI links UIKit, so it and its tests build only for
        // iOS; on macOS the ExtensionUI test target compiles to an empty bundle
        // (its UIKit dependency is `.when(platforms: [.iOS])` and its sources are
        // `#if canImport(UIKit)`). App and extensions deploy against iOS only.
        .macOS(.v15)
    ],
    products: [
        // One product, five layered targets. App and extension targets import the
        // specific modules they need; the dependency direction below is the
        // architecture, enforced by the compiler.
        .library(
            name: "LinkCleanKit",
            targets: [
                "LinkCleanCore",
                "LinkCleanData",
                "LinkCleanAnalytics",
                "LinkCleanExtensionUI",
                "LinkCleanIntents"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/TelemetryDeck/SwiftSDK", from: "2.0.0")
    ],
    targets: [
        // Pure domain. No dependencies, no resources. Default (nonisolated) actor
        // isolation — it matches the contents, so no `nonisolated` annotations are
        // needed, and the layer builds on macOS via `swift build --target LinkCleanCore`.
        .target(
            name: "LinkCleanCore"
        ),
        // Persistence over UserDefaults + SwiftData. Keeps MainActor default
        // isolation so the SwiftData `@Model` types and the store/service protocols
        // retain the isolation they had before the split.
        .target(
            name: "LinkCleanData",
            dependencies: ["LinkCleanCore"],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
        // The TelemetryDeck binding — the only target that links the SDK, so a
        // future analytics-backend swap touches exactly one target.
        .target(
            name: "LinkCleanAnalytics",
            dependencies: [
                "LinkCleanCore",
                "LinkCleanData",
                .product(name: "TelemetryDeck", package: "SwiftSDK")
            ]
        ),
        // UIKit action-extension host + the only string catalog in the package
        // (toast strings). MainActor default isolation, where `Bundle.module` is
        // main-actor-isolated — the conflict that used to constrain the whole kit
        // now lives only here.
        .target(
            name: "LinkCleanExtensionUI",
            dependencies: [
                "LinkCleanCore",
                "LinkCleanData",
                "LinkCleanAnalytics"
            ],
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
        // The App Intents surface (S1): the Shortcuts / Siri / Spotlight /
        // Action-button / Control Center / widget intents. UIKit (`UIPasteboard`)
        // + the AppIntents framework, MainActor default isolation. iOS-only — its
        // sources are `#if canImport(UIKit)`, so on macOS it compiles to an empty
        // module and the fast lane (`swift test`) stays green, exactly like
        // LinkCleanExtensionUI. The app target and the (Phase B) widget extension
        // both link it; the intents are defined once here, not per binary.
        .target(
            name: "LinkCleanIntents",
            dependencies: [
                "LinkCleanCore",
                "LinkCleanData",
                "LinkCleanAnalytics"
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),

        // MARK: - Test support

        // Shared doubles/fixtures for every test suite (one `SpyAnalytics`, not a
        // copy per suite). A regular target depended on by the test targets — not
        // a member of any product, so it never ships. Core+Data only (no UIKit),
        // so it builds on the macOS fast lane.
        .target(
            name: "LinkCleanTestSupport",
            dependencies: ["LinkCleanCore", "LinkCleanData"],
            path: "Tests/LinkCleanTestSupport"
        ),

        // MARK: - Test suites (two-speed)

        // Fast lane — run on macOS with `swift test`. Pure domain.
        .testTarget(
            name: "LinkCleanCoreTests",
            dependencies: ["LinkCleanCore", "LinkCleanTestSupport"],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
        // Fast lane — run on macOS with `swift test`. Persistence over
        // UserDefaults + an in-memory SwiftData container.
        .testTarget(
            name: "LinkCleanDataTests",
            dependencies: ["LinkCleanCore", "LinkCleanData", "LinkCleanTestSupport"],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
        // Sim lane — UIKit, so the ExtensionUI dependency is iOS-only and the
        // sources are `#if canImport(UIKit)`. On macOS this builds to an empty
        // test bundle (so `swift test` stays green without a simulator); the real
        // tests run via the LinkCleanKit scheme on the iOS simulator.
        .testTarget(
            name: "LinkCleanExtensionUITests",
            dependencies: [
                "LinkCleanCore",
                "LinkCleanData",
                "LinkCleanTestSupport",
                .target(name: "LinkCleanExtensionUI", condition: .when(platforms: [.iOS]))
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
    ]
)
