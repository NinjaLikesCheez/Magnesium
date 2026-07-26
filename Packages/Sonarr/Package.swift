// swift-tools-version: 6.2
import PackageDescription

let package = Package(
	name: "SonarrFeature",
	platforms: [.iOS(.v26), .macOS(.v26), .tvOS(.v26), .visionOS(.v26)],
	products: [
		.library(name: "SonarrUI", targets: ["SonarrUI"]),
		.library(name: "SonarrCore", targets: ["SonarrCore"]),
		.library(name: "SonarrSession", targets: ["SonarrSession"]),
	],
	dependencies: [
		.package(path: "../Common"),
		.package(path: "../MagnesiumModule"),
		.package(url: "https://github.com/NinjaLikesCheez/sonarr-swift", branch: "main"),
		.package(url: "https://github.com/pointfreeco/swift-navigation", from: "2.4.1"),
		.package(url: "https://github.com/apple/swift-log", from: "1.6.2"),
		.package(url: "https://github.com/fatbobman/ObservableDefaults", from: "1.7.0"),
	],
	targets: [
		.target(
			name: "SonarrCore",
			dependencies: [
				"Common"
			]
		),
		.target(
			name: "SonarrSession",
			dependencies: [
				"SonarrCore",
				"Common",
				.product(name: "Sonarr", package: "sonarr-swift"),
				.product(name: "Logging", package: "swift-log"),
				.product(name: "ObservableDefaults", package: "ObservableDefaults"),
			]
		),
		.target(
			name: "SonarrUI",
			dependencies: [
				"SonarrCore",
				"SonarrSession",
				.product(name: "Common", package: "Common"),
				.product(name: "CommonUI", package: "Common"),
				.product(name: "MagnesiumModule", package: "MagnesiumModule"),
				.product(name: "SwiftNavigation", package: "swift-navigation"),
				.product(name: "SwiftUINavigation", package: "swift-navigation"),
			]
		),
		.testTarget(name: "SonarrCoreTests", dependencies: ["SonarrCore"]),
		.testTarget(name: "SonarrSessionTests", dependencies: ["SonarrSession"]),
	]
)
