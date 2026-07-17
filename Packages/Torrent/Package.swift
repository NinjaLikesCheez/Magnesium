// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Torrent",
	platforms: [.iOS(.v26), .tvOS(.v26), .visionOS(.v26), .macOS(.v26)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "TorrentUI",
			targets: ["TorrentUI"]
		),
		.library(
			name: "TorrentCore",
			targets: ["TorrentCore"]
		),
		.library(
			name: "TorrentSession",
			targets: ["TorrentSession"]
		),
		.library(
			name: "TorrentManager",
			targets: ["TorrentManager"]
		),
		.library(
			name: "TorrentMapping",
			targets: ["TorrentMapping"]
		),
		.library(
			name: "TorrentPreferences",
			targets: ["TorrentPreferences"]
		),
	],
	dependencies: [
		.package(path: "../Common"),
		.package(path: "../MagnesiumModule"),
		.package(url: "https://github.com/NinjaLikesCheez/Deluge-Swift", from: "2.0.0"),
		.package(url: "https://github.com/NinjaLikesCheez/qBittorrent-Swift", from: "0.0.2"),
		.package(url: "https://github.com/fatbobman/ObservableDefaults", from: "1.7.0"),
		.package(url: "https://github.com/pointfreeco/swift-navigation", from: "2.4.1"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "TorrentUI",
			dependencies: [
				"TorrentManager",
				"TorrentSession",
				.product(name: "CommonUI", package: "Common"),
				.product(name: "MagnesiumModule", package: "MagnesiumModule"),
				.product(name: "SwiftNavigation", package: "swift-navigation"),
				.product(name: "SwiftUINavigation", package: "swift-navigation"),
			]
		),
		.target(
			name: "TorrentManager",
			dependencies: ["TorrentSession"]
		),
		.target(
			name: "TorrentSession",
			dependencies: [
				"TorrentCore",
				"TorrentPreferences",
				"TorrentMapping",
				.product(name: "Deluge", package: "Deluge-Swift"),
				.product(name: "QBittorrent", package: "qBittorrent-Swift"),
			]
		),
		.target(
			name: "TorrentMapping",
			dependencies: [
				"TorrentCore",
				.product(name: "Deluge", package: "Deluge-Swift"),
				.product(name: "QBittorrent", package: "qBittorrent-Swift"),
			]
		),
		.target(
			name: "TorrentPreferences",
			dependencies: [
				"TorrentCore",
				.product(name: "ObservableDefaults", package: "ObservableDefaults"),
			]
		),
		.target(
			name: "TorrentCore",
			dependencies: ["Common"]
		),
		.target(
			name: "TorrentTestSupport",
			dependencies: [
				"TorrentCore",
				"TorrentSession",
				"TorrentPreferences",
			]
		),
		.testTarget(
			name: "TorrentCoreTests",
			dependencies: [
				"TorrentTestSupport",
				"TorrentCore",
			]
		),
		.testTarget(
			name: "TorrentMappingTests",
			dependencies: [
				"TorrentTestSupport",
				"TorrentCore",
				"TorrentMapping",
			]
		),
		.testTarget(
			name: "TorrentPreferencesTests",
			dependencies: [
				"TorrentTestSupport",
				"TorrentCore",
				"TorrentPreferences",
				"Common",
			]
		),
		.testTarget(
			name: "TorrentSessionTests",
			dependencies: [
				"TorrentTestSupport",
				"TorrentCore",
				"TorrentPreferences",
				"TorrentSession",
				"Common",
			]
		),
		.testTarget(
			name: "TorrentManagerTests",
			dependencies: [
				"TorrentTestSupport",
				"TorrentCore",
				"TorrentSession",
				"TorrentManager",
				"TorrentMapping",
				"TorrentPreferences",
				"Common",
			]
		),
	]
)
