//
//  TorrentOnboardingFlow.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import SwiftUI
import Router

public struct TorrentOnboardingFlow: Flow {
	public typealias Router = TorrentOnboardingRouter

	@State public var router: TorrentOnboardingRouter = .init()

	@Binding var preferences: TorrentPreferences
	@Binding var session: TorrentSession

	public var body: some View {
		NavigationStack(path: $router.path) {
			TorrentOnboardingView()
				.withTorrentOnboardingDestinations()
				.withTorrentOnboardingSheets(router: $router, preferences: $preferences, session: $session)
		}
		.withTorrentOnboardingErrors(router: $router)
		.environment(router)
		.environment(preferences)
		.environment(session)
	}
}
