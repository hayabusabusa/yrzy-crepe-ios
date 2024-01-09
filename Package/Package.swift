// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Package",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "Package",
            targets: ["Package"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            .upToNextMajor(from: "10.19.0")),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            .upToNextMajor(from: "1.6.0")),
    ],
    targets: [
        .target(
            name: "Package"),
        .testTarget(
            name: "PackageTests",
            dependencies: ["Package"]),
    ]
)
