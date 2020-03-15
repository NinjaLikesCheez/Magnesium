// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Components",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "Coordinator", targets: ["Coordinator"]),
        .library(name: "Preferences", targets: ["Preferences"]),
        .library(name: "ViewModel", targets: ["ViewModel"]),
    ],
    targets: [
        .target(name: "Coordinator"),
        .target(name: "Preferences"),
        .target(name: "ViewModel"),
        .testTarget(name: "PreferencesTests", dependencies: [.target(name: "Preferences")]),
    ]
)
