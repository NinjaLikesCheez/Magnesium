// The Swift Programming Language
// https://docs.swift.org/swift-book

import Router

@MainActor
public protocol MagnesiumFeatureModule<EntryPoint, SettingsFlow, OnboardingFlow> {
	associatedtype EntryPoint: Flow
	associatedtype SettingsFlow: Flow
	associatedtype OnboardingFlow: Flow

	var entry: EntryPoint { get }
	var settings: SettingsFlow { get }
	var onboarding: OnboardingFlow? { get }
}
