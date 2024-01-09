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
        .library(
            name: "FirestoreClient",
            targets: ["FirestoreClient"]),
        .library(
            name: "FirestoreClientLive",
            targets: ["FirestoreClientLive"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "10.19.0"),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.6.0"),
        .package(
            url: "https://github.com/pointfreeco/swift-dependencies",
            from: "1.1.5"),
    ],
    targets: [
        .target(
            name: "FirestoreClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]),
        .target(
            name: "FirestoreClientLive",
            dependencies: [
                "FirestoreClient",
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]),
        .target(
            name: "Package"),
        .testTarget(
            name: "PackageTests",
            dependencies: ["Package"]),
    ]
)
