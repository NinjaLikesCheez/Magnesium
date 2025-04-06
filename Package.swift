// swift-tools-version:5.7
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import PackageDescription

// This purely exists to allow the LSP to work.

var package = Package(
	name: "Magnesium",
	defaultLocalization: "en",
	products: [
		.library(
			name: "Magnesium",
			targets: ["Magnesium"])
	],
	dependencies: [],
	targets: [
		// Core Library
		.target(
			name: "Magnesium",
			dependencies: [],
			exclude: [])
	]
)
