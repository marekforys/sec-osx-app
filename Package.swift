// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sec-osx-app",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "sec-osx-app",
            targets: ["sec-osx-app"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "sec-osx-app",
            dependencies: [],
            path: "sec-osx-app"
        ),
        .testTarget(
            name: "sec-osx-appTests",
            dependencies: ["sec-osx-app"],
            path: "sec-osx-appTests"
        )
    ]
)
