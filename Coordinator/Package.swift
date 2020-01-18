// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Coordinator",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Coordinator",
            targets: ["Coordinator"]),
    ],
    targets: [
        .target(
            name: "Coordinator",
            dependencies: []),
        .testTarget(
            name: "CoordinatorTests",
            dependencies: ["Coordinator"]),
    ]
)
