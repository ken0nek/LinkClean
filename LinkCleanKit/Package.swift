// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LinkCleanKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "LinkCleanKit",
            targets: ["LinkCleanKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/TelemetryDeck/SwiftSDK", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "LinkCleanKit",
            dependencies: [
                .product(name: "TelemetryDeck", package: "SwiftSDK")
            ],
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
        .testTarget(
            name: "LinkCleanKitTests",
            dependencies: ["LinkCleanKit"],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
    ]
)
