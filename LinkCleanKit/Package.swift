// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LinkCleanKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "LinkCleanKit",
            targets: ["LinkCleanKit"]
        )
    ],
    targets: [
        .target(
            name: "LinkCleanKit",
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
        .testTarget(
            name: "LinkCleanKitTests",
            dependencies: ["LinkCleanKit"]
        ),
    ]
)
