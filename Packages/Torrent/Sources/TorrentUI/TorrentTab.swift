//
//  TorrentTab.swift
//  Torrent
//
//  Created by ninji on 30/09/2025.
//

import Common
import SwiftUI

public struct TorrentTab: View {
	@State var session: TorrentSession
	@State var preferences: TorrentPreferences
	@State var manager: TorrentManager

	public init() {
		self._preferences = .init(
			initialValue: TorrentPreferences(userDefaults: .standard, keychain: SystemKeychain())
		)
		self._session = .init(
			initialValue: TorrentSession(_preferences.wrappedValue)
		)
		self._manager = .init(
			initialValue: TorrentManager(session: _session.wrappedValue, preferences: _preferences.wrappedValue)
		)
	}

	public var body: some View {
		TorrentsListFlow(
			torrentListRouter: .init(),
			torrentManager: $manager,
			preferences: $preferences,
			session: $session
		)
		// TODO: Rework this to show a 'setup torrent client' screen internal to the package
//		.task {
//			guard session.server != nil else {
//				appState = .unauthenticated
//				return
//			}
//
//			appState = .authenticated
//		}
//		.onChange(of: session.server) { _, newValue in
//			guard newValue != nil else {
//				appState = .unauthenticated
//				return
//			}
//
//			appState = .authenticated
//		}
		.environment(preferences)
		.environment(session)
	}
}
