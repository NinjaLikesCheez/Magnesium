// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "MagnesiumModule",
	platforms: [.iOS(.v26), .tvOS(.v26), .visionOS(.v26), .macOS(.v26)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "MagnesiumModule",
			targets: ["MagnesiumModule"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/NinjaLikesCheez/Router.git", branch: "main")
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "MagnesiumModule",
			dependencies: ["Router"]
		),
		.testTarget(
			name: "MagnesiumModuleTests",
			dependencies: ["MagnesiumModule"]
		),
	]
)
