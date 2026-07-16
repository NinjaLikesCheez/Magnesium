@_exported import TorrentManager
import Router
import Observation
import SwiftUI
import MagnesiumModule
import Common

@MainActor
public class TorrentModule: MagnesiumFeatureModule, Equatable, Hashable {
	public typealias EntryPoint = TorrentsListFlow
	public typealias SettingsFlow = TorrentSettingsFlow
	public typealias OnboardingFlow = TorrentOnboardingFlow

	let session: TorrentSession
	let preferences: TorrentPreferences
	let manager: TorrentManager

	let parentRouter: (any Routable)?

	public init(_ parentRouter: (any Routable)? = nil) {
		preferences = .init(userDefaults: .standard, keychain: SystemKeychain())
		session = .init(preferences)
		manager = .init(session: session, preferences: preferences)
		self.parentRouter = parentRouter
	}

	public let name: String  = "Torrent"

	public var icon: Image { Image(systemName: "square.and.arrow.down") }

	public var entry: TorrentsListFlow {
		.init(session: session, preferences: preferences, manager: manager)
	}

	public var settings: TorrentSettingsFlow {
		.init(preferences: preferences, session: session)
	}

	public var onboarding: TorrentOnboardingFlow {
		.init(preferences: preferences, session: session)
	}

	public var isEnabled: Bool {
		session.server != nil
	}

	public func reset() {
		preferences.reset()
		session.reset()
	}

	public nonisolated static func == (lhs: TorrentModule, rhs: TorrentModule) -> Bool {
		ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
	}

	nonisolated public func hash(into hasher: inout Hasher) {
		// TODO: this is terrible...
		hasher.combine(name)
	}
}

