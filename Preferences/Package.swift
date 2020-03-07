// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Preferences",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "Preferences", targets: ["Preferences"]),
    ],
    targets: [
        .target(name: "Preferences"),
        .testTarget(name: "PreferencesTests", dependencies: [.target(name: "Preferences")]),
    ]
)
