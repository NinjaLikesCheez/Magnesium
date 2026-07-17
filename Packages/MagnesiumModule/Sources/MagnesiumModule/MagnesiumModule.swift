// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftUI

@MainActor
public protocol MagnesiumFeatureModule<EntryPoint, SettingsFlow, OnboardingFlow>: Identifiable {
	associatedtype EntryPoint: View
	associatedtype SettingsFlow: View
	associatedtype OnboardingFlow: View

	var name: String { get }
	var icon: Image { get }

	var isEnabled: Bool { get }

	var entry: EntryPoint { get }
	var settings: SettingsFlow { get }
	var onboarding: OnboardingFlow { get }

	func reset()
}

extension MagnesiumFeatureModule {
	var id: String { name }
}
