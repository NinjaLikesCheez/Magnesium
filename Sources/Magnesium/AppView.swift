//
//  AppTabs.swift
//  Magnesium
//
//  Created by ninji on 03/11/2025.
//

import Common
import Logging
import SwiftUI
import SwiftUINavigation
import TorrentUI

struct AppView: View {
	@Environment(AppModules.self) var modules

	@State private var appState = AppState.resuming
	@State private var appPreferences = AppPreferences()
	@State private var model = Model()

	var body: some View {
		@Bindable var model = model

		Group {
			switch appState {
			case .unboarded:
				NavigationStack {
					modules
						.torrent
						.onboarding
				}
			case .onboarded:
				NavigationStack {
					modules
						.torrent
						.entry
						.toolbar {
							#if os(macOS)
								ToolbarItem(placement: .primaryAction) {
									Button {
										model.sheet = .settings
									} label: {
										Image(systemName: "gear")
									}
								}
							#else
								ToolbarItem(placement: .topBarLeading) {
									Button {
										model.sheet = .settings
									} label: {
										Image(systemName: "gear")
									}
								}
							#endif
						}
						.sheet(item: $model.sheet) { sheet in
							switch sheet {
							case .settings:
								SettingsFlow()
									.environment(modules)
							}
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
			appState = modules.torrent.isEnabled ? .onboarded : .unboarded
			//			appState = appPreferences.onboarded ? .onboarded : .unboarded
		}
		.onChange(of: modules.torrent.isEnabled) { _, newValue in
			appState = newValue ? .onboarded : .unboarded
		}
	}
}

extension AppView {
	@Observable
	final class Model {
		var sheet: Sheet?

		init() {}

		@CasePathable
		enum Sheet: Hashable, Identifiable {
			case settings

			var id: Self { self }
		}
	}
}
