// swift-tools-version: 6.2
import PackageDescription

let package = Package(
	name: "Common",
	platforms: [.iOS(.v26), .macOS(.v26), .tvOS(.v26), .visionOS(.v26)],
	products: [
		.library(
			name: "Common",
			targets: ["Common"]
		)
	],
	dependencies: [
		// TODO: these dependencies need to be refactored out
		.package(url: "https://github.com/NinjaLikesCheez/Deluge-Swift", from: "1.2.0"),
		.package(url: "https://github.com/NinjaLikesCheez/QBittorrent-Swift", from: "0.0.1"),
		.package(url: "https://github.com/fatbobman/ObservableDefaults/", from: "1.6.0"),
	],
	targets: [
		.target(
			name: "Common",
				dependencies: [
					.product(name: "Deluge", package: "Deluge-Swift"),
					.product(name: "QBittorrent", package: "QBittorrent-Swift"),
					.product(name: "ObservableDefaults", package: "ObservableDefaults"),
			],
			path: "Sources/Common"
		),
		.testTarget(
			name: "CommonTests",
			dependencies: ["Common"]
		),
	]
)
