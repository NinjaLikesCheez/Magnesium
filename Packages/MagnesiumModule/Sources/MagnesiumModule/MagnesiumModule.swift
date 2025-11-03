// The Swift Programming Language
// https://docs.swift.org/swift-book

import Router

@MainActor
public protocol MagnesiumFeatureModule<EntryPoint, SettingsFlow> {
	associatedtype EntryPoint: Flow
	associatedtype SettingsFlow: Flow

	static var entry: EntryPoint { get }
	static var settings: SettingsFlow { get }
}
