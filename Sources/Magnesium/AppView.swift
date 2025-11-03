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
	@State private var appState = AppState.resuming
	@State private var appPreferences = AppPreferences()
	@State var showingSettings = false

	var body: some View {
		Group {
			switch appState {
			case .unboarded:
				OnboardingFlow(router: .init())
			case .onboarded:
				NavigationStack {
					TorrentModule
						.entry
						.toolbar {
#if os(macOS)
							ToolbarItem(placement: .primaryAction) {
								Button {
									showingSettings.toggle()
								} label: {
									Image(systemName: "gear")
								}
							}
#else
							ToolbarItem(placement: .topBarLeading) {
								Button {
									showingSettings.toggle()
								} label: {
									Image(systemName: "gear")
								}
							}
#endif
						}
						.sheet(isPresented: $showingSettings) {
							SettingsFlow(router: .init())
						}
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
			appState = appPreferences.onboarded ? .onboarded : .unboarded
		}
		.onChange(of: appPreferences.onboarded) { _, newValue in
			appState = newValue ? .onboarded : .unboarded
		}
	}
}
