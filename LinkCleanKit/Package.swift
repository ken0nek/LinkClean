// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LinkCleanKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
        // Declared so the non-UIKit layers build on the Mac host via
        // `swift build --target LinkCleanCore` (and Data/Analytics) — the fast
        // feedback loop the split unlocks. Full `swift test` on macOS still awaits
        // splitting the test target off LinkCleanExtensionUI/UIKit; until then a
        // bare `swift build`/`swift test` pulls in UIKit and fails. App and
        // extensions deploy against iOS only.
        .macOS(.v15)
    ],
    products: [
        // One product, four layered targets. App and extension targets import the
        // specific modules they need; the dependency direction below is the
        // architecture, enforced by the compiler.
        .library(
            name: "LinkCleanKit",
            targets: [
                "LinkCleanCore",
                "LinkCleanData",
                "LinkCleanAnalytics",
                "LinkCleanExtensionUI"
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
        // One test target spanning all four layers for now; the two-speed
        // macOS/simulator split is a separate step.
        .testTarget(
            name: "LinkCleanKitTests",
            dependencies: [
                "LinkCleanCore",
                "LinkCleanData",
                "LinkCleanAnalytics",
                "LinkCleanExtensionUI"
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
    ]
)
