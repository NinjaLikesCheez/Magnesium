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
		)
	],
	dependencies: [
		.package(path: "../Common"),
		.package(url: "https://github.com/NinjaLikesCheez/Deluge-Swift", from: "1.2.0"),
		.package(url: "https://github.com/NinjaLikesCheez/qBittorrent-Swift", from: "0.0.2"),
		.package(url: "https://github.com/NinjaLikesCheez/Router", from: "1.0.0"),
		.package(url: "https://github.com/fatbobman/ObservableDefaults", from: "1.7.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "TorrentUI",
			dependencies: [
				"TorrentManager",
				"TorrentSession",
				.product(name: "Router", package: "Router"),
				.product(name: "CommonUI", package: "Common"),
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
		.testTarget(
			name: "TorrentUITests",
			dependencies: ["TorrentUI"]
		),
	]
)
