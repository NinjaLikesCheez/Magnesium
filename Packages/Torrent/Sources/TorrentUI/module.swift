@_exported import TorrentManager
import Router
import Observation
import SwiftUI
import MagnesiumModule
import Common

@MainActor
@Observable
public class TorrentModule: MagnesiumFeatureModule {
	public typealias EntryPoint = TorrentsListFlow
	public typealias SettingsFlow = TorrentSettingsFlow
	public typealias OnboardingFlow = TorrentOnboardingFlow

	private var session: TorrentSession
	private var preferences: TorrentPreferences
	private var manager: TorrentManager

	public var entry: EntryPoint
	public var settings: SettingsFlow
	public var onboarding: OnboardingFlow?

	public init() {
		preferences = TorrentPreferences(userDefaults: .standard, keychain: SystemKeychain())
		session = TorrentSession(preferences)
		manager = TorrentManager(session: session, preferences: preferences)

		let bindable = Bindable(self)
		self.entry = .init(session: bindable.session, preferences: bindable.preferences, manager: bindable.manager)
		self.settings = .init(preferences: bindable.preferences, session: bindable.session)
		self.onboarding = .init(preferences: bindable.preferences, session: bindable.session)
	}
}

//@MainActor
//public struct TorrentModule: @MainActor MagnesiumFeatureModule {
//	public typealias EntryPoint = TorrentsListFlow
//	public typealias SettingsFlow = SettingsFlow2
//
//	static public var entry: EntryPoint = {
//		TorrentsListFlow()
//	}()
//	static public var settings: SettingsFlow = {
//		SettingsFlow2(router: .init())
//	}()
//}
//
//extension Never: @retroactive RoutableDestination, @retroactive RoutableSheet, @retroactive RoutableError {}
///// Handles navigation within the settings screen.
//@Observable
//final class SettingsRouter: Routable {
//	typealias Destination = Never
//	typealias Sheet = Never
//	typealias Error = Never
//
//	var path: [Destination] = []
//	var presentedSheet: Sheet? = nil
//	var presentedError: Error? = nil
//	let parent: (any Routable)?
//
//	required init(_ parent: (any Routable)? = nil) {
//		self.parent = parent
//	}
//}
//
//
//public struct SettingsFlow2: Flow {
//	var router: SettingsRouter = .init()
//
//	typealias Router = SettingsRouter
//
//	public var body: some View {
//		Text("Hello")
//	}
//}
//
