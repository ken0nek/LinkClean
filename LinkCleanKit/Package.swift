// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LinkCleanKit",
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
            name: "LinkCleanKit"
        ),
        .testTarget(
            name: "LinkCleanKitTests",
            dependencies: ["LinkCleanKit"]
        ),
    ]
)
