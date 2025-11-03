@_exported import TorrentManager
import Router
import Observation
import SwiftUI
import MagnesiumModule

@MainActor
public struct TorrentModule: MagnesiumFeatureModule {
	public typealias EntryPoint = TorrentsListFlow
	public typealias SettingsFlow = TorrentSettingsFlow

	public static var entry: TorrentsListFlow { .init() }

	public static var settings: TorrentSettingsFlow { .init() }
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
