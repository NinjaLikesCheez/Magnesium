// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Transmission",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Transmission",
            targets: ["Transmission"]
        ),
    ],
    targets: [
        .target(
            name: "Transmission",
            dependencies: []
        ),
    ]
)
