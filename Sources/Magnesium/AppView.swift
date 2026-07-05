//
//  AppTabs.swift
//  Magnesium
//
//  Created by ninji on 03/11/2025.
//

import SwiftUI
import Router

import Common
import Logging
import SwiftUI
import TorrentUI

struct AppView: View {
	@Environment(AppModules.self) var modules

	@State private var appState = AppState.resuming
	@State private var appPreferences = AppPreferences()
	@State private var router = AppRouter()

	var body: some View {
		Group {
			switch appState {
			case .unboarded:
//				OnboardingFlow(router: .init())
				modules
					.torrent
					.onboarding
			case .onboarded:
				NavigationStack {
					modules
						.torrent
						.entry
						.toolbar {
#if os(macOS)
							ToolbarItem(placement: .primaryAction) {
								Button {
									router.presentSheet(.settings)
								} label: {
									Image(systemName: "gear")
								}
							}
#else
							ToolbarItem(placement: .topBarLeading) {
								Button {
									router.presentSheet(.settings)
								} label: {
									Image(systemName: "gear")
								}
							}
#endif
						}
						.withAppSheets(router: router, modules: modules)
				}
			case .resuming:
				ProgressView()
					.containerRelativeFrame([.horizontal, .vertical])
			case .error(let error):
				ContentUnavailableView(
					"Error: \(error.localizedDescription)",
					image: "exclamationmark.triangle"
				)
			}
		}
		.task {
			appState = modules.torrent.isEnabled ? .onboarded : .unboarded
//			appState = appPreferences.onboarded ? .onboarded : .unboarded
		}
		.onChange(of: modules.torrent.isEnabled) { _, newValue in
			appState = newValue ? .onboarded : .unboarded
		}
	}
}
