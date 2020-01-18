// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Deluge",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Deluge",
            targets: ["Deluge"]
        ),
    ],
    targets: [
        .target(
            name: "Deluge",
            dependencies: []
        ),
    ]
)
