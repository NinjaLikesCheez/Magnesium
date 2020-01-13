// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Preferences",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Preferences",
            targets: ["Preferences"]
        ),
    ],
    targets: [
        .target(
            name: "Preferences",
            dependencies: []
        ),
        .testTarget(
            name: "PreferencesTests",
            dependencies: ["Preferences"]
        ),
    ]
)
