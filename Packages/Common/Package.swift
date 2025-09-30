// swift-tools-version: 6.2
import PackageDescription

let package = Package(
	name: "Common",
	platforms: [.iOS(.v26), .macOS(.v26), .tvOS(.v26), .visionOS(.v26)],
	products: [
		.library(
			name: "Common",
			targets: ["Common"]
		),
		.library(
			name: "CommonUI",
			targets: ["CommonUI"]
		),
	],
	dependencies: [],
	targets: [
		.target(
			name: "Common",
		),
		.target(
			name: "CommonUI",
			dependencies: ["Common"]
		),
		// .testTarget(
		// 	name: "CommonTests",
		// 	dependencies: ["Common"]
		// ),
	]
)
