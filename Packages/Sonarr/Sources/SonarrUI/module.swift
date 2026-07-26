import Common
import MagnesiumModule
import Observation
@_exported import SonarrSession
import SwiftUI

@MainActor
public class SonarrModule: MagnesiumFeatureModule, Equatable, Hashable {
	public typealias EntryPoint = SonarrSeriesListFlow
	public typealias SettingsFlow = SonarrSettingsFlow
	public typealias OnboardingFlow = SonarrOnboardingFlow

	let session: SonarrSession
	let preferences: SonarrPreferences

	public init() {
		preferences = .init(userDefaults: .standard, keychain: SystemKeychain())
		session = .init(preferences)
	}

	public let name: String = "Sonarr"

	public var iconSystemName: String { "tv" }

	public var entry: SonarrSeriesListFlow {
		.init(session: session, preferences: preferences)
	}

	public var settings: SonarrSettingsFlow {
		.init(preferences: preferences, session: session)
	}

	public var onboarding: SonarrOnboardingFlow {
		.init(preferences: preferences, session: session)
	}

	public var isEnabled: Bool {
		session.server != nil
	}

	public func reset() {
		preferences.reset()
		session.reset()
	}

	public nonisolated static func == (lhs: SonarrModule, rhs: SonarrModule) -> Bool {
		ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
	}

	nonisolated public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}
}
