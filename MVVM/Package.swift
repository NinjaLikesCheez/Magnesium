// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "MVVM",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "MVVM", targets: ["Coordinator", "ViewModel"]),
    ],
    targets: [
        .target(name: "Coordinator"),
        .target(name: "ViewModel"),
    ]
)
