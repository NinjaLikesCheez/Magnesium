//
//  CompactTorrentsView.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//

import SwiftUI
import Router
import Common

public struct TorrentsListFlow: Flow {
	public typealias Router = TorrentListRouter

	// TODO: fix plz
	@State public var router: TorrentListRouter = .init()
	@State private var session: TorrentSession
	@State private var preferences: TorrentPreferences
	@State private var manager: TorrentManager

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
		NavigationStack(path: $router.path) {
			TorrentNavigationView()
				.withTorrentListDestinations(
					manager: $manager
				)
				.withTorrentListSheets(
					router: $router,
					preferences: $preferences,
					session: $session
				)
		}
		.withTorrentListErrors(router: $router)
		.environment(manager)
		.environment(router)
		.environment(preferences)
		.environment(session)
	}
}
