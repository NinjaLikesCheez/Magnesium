//
//  AppTabs.swift
//  Magnesium
//
//  Created by ninji on 03/11/2025.
//

import Common
import Logging
import MagnesiumModule
import SonarrUI
import SwiftUI
import SwiftUINavigation
import TorrentUI

struct AppView: View {
	@Environment(AppModules.self) var modules

	@State private var model = Model()

	var body: some View {
		@Bindable var model = model

		TabView {
			ForEach(modules.modules) { moduleType in
				Tab(moduleType.rawValue.name, systemImage: moduleType.rawValue.iconSystemName) {
					NavigationStack {
						ModuleTabView(moduleType: moduleType)
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
				}
			}
		}
	}
}

/// Shows a single feature module's onboarding flow or entry point, depending on whether it's
/// currently configured (`isEnabled`). Each tab tracks this independently — unlike the old
/// single-module app, one feature being unconfigured no longer blocks the others.
private struct ModuleTabView: View {
	let moduleType: AppModules.ModuleType

	@State private var isEnabled = false

	var body: some View {
		Group {
			switch moduleType {
			case let .torrent(module):
				if isEnabled {
					module.entry
				} else {
					module.onboarding
				}
			case let .sonarr(module):
				if isEnabled {
					module.entry
				} else {
					module.onboarding
				}
			}
		}
		.task { isEnabled = moduleType.rawValue.isEnabled }
		.onChange(of: moduleType.rawValue.isEnabled) { _, newValue in isEnabled = newValue }
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
