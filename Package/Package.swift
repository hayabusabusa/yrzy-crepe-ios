// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Package",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "AppFeature",
            targets: ["AppFeature"]),
        .library(
            name: "AuthClient",
            targets: ["AuthClient"]),
        .library(
            name: "AuthClientLive",
            targets: ["AuthClientLive"]),
        .library(
            name: "BookshelfFeature",
            targets: ["BookshelfFeature"]),
        .library(
            name: "FavoritesFeature",
            targets: ["FavoritesFeature"]),
        .library(
            name: "FirebaseClient",
            targets: ["FirebaseClient"]),
        .library(
            name: "FirebaseClientLive",
            targets: ["FirebaseClientLive"]),
        .library(
            name: "FirestoreClient",
            targets: ["FirestoreClient"]),
        .library(
            name: "FirestoreClientLive",
            targets: ["FirestoreClientLive"]),
        .library(
            name: "GalleryFeature",
            targets: ["GalleryFeature"]),
        .library(
            name: "RandomDateGenerator",
            targets: ["RandomDateGenerator"]),
        .library(
            name: "SearchFeature",
            targets: ["SearchFeature"]),
        .library(
            name: "SharedExtensions",
            targets: ["SharedExtensions"]),
        .library(
            name: "SharedViews",
            targets: ["SharedViews"]),
        .library(
            name: "ViewerFeature",
            targets: ["ViewerFeature"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "10.19.0"),
        .package(
            url: "https://github.com/kean/Nuke.git",
            from: "12.3.0"),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.6.0"),
        .package(
            url: "https://github.com/pointfreeco/swift-dependencies",
            from: "1.1.5"),
        .package(
            url: "https://github.com/fermoya/SwiftUIPager.git",
            from: "2.5.0"),
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: [
                "FirebaseClient",
                "GalleryFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]),
        .target(
            name: "AuthClient",
            dependencies: [
                "SharedModels",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]),
        .target(
            name: "AuthClientLive",
            dependencies: [
                "AuthClient",
                "SharedModels",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
            ]),
        .target(
            name: "FirebaseClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]),
        .target(
            name: "FirebaseClientLive",
            dependencies: [
                "FirebaseClient",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            ]),
        .target(
            name: "FirestoreClient",
            dependencies: [
                "SharedModels",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]),
        .target(
            name: "FirestoreClientLive",
            dependencies: [
                "FirestoreClient",
                "SharedModels",
                "SharedExtensions",
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
            ]),
        .target(
            name: "BookshelfFeature",
            dependencies: [
                "FirestoreClient",
                "SharedModels",
                "SharedExtensions",
                "ViewerFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "NukeUI", package: "Nuke")
            ]),
        .target(
            name: "FavoritesFeature",
            dependencies: [
                "AuthClient",
                "FirestoreClient",
                "SharedModels",
                "SharedExtensions",
                "SharedViews",
                "ViewerFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "NukeUI", package: "Nuke"),
            ]),
        .target(
            name: "GalleryFeature",
            dependencies: [
                "AuthClient",
                "BookshelfFeature",
                "FavoritesFeature",
                "FirestoreClient",
                "RandomDateGenerator",
                "SearchFeature",
                "SharedModels",
                "SharedExtensions",
                "SharedViews",
                "ViewerFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "NukeUI", package: "Nuke"),
            ]),
        .target(
            name: "RandomDateGenerator",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]),
        .target(
            name: "SearchFeature",
            dependencies: [
                "FirestoreClient",
                "SharedModels",
                "SharedExtensions",
                "ViewerFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "NukeUI", package: "Nuke"),
            ]),
        .target(
            name: "SharedExtensions"),
        .target(
            name: "SharedModels"),
        .target(
            name: "SharedViews"),
        .target(
            name: "ViewerFeature",
            dependencies: [
                "AuthClient",
                "FirestoreClient",
                "SharedModels",
                "SharedViews",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "NukeUI", package: "Nuke"),
                .product(name: "SwiftUIPager", package: "SwiftUIPager"),
            ]),
        .testTarget(
            name: "RandomDateGeneratorTests",
            dependencies: [
                "RandomDateGenerator",
            ]),
        .testTarget(
            name: "SharedExtensionsTests",
            dependencies: [
                "SharedExtensions",
            ]
        ),
    ]
)
