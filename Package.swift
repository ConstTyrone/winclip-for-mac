// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClipMaster",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "ClipMaster",
            targets: ["ClipMaster"]
        )
    ],
    dependencies: [
        // 暂时移除外部依赖，使用内建实现
        // .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.15.0"),
        // .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.14.1"),
    ],
    targets: [
        .executableTarget(
            name: "ClipMaster",
            dependencies: [
                // "KeyboardShortcuts",
                // .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources/ClipMaster"
        ),
        .testTarget(
            name: "ClipMasterTests",
            dependencies: ["ClipMaster"],
            path: "Tests/ClipMasterTests"
        )
    ]
)
