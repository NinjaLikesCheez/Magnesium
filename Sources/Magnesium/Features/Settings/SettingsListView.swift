import Common
import CommonUI
import SwiftUI
import SwiftUINavigation
import TorrentUI

public struct SettingsListView: View {
	@Environment(AppModules.self) private var modules: AppModules
	@Environment(\.dismiss) private var dismiss

	@State private var model = Model()

	public var body: some View {
		@Bindable var model = model

		List {
			modulesSection

			resetSection
		}
		.navigationTitle("Settings")
		.navigationDestination(item: $model.destination.moduleSettings) { moduleType in
			switch moduleType {
			case let .torrent(module):
				module.settings
			}
		}
		.panel(item: $model.error) { error in
			switch error {
			case let .preferences(error):
				ErrorPanelCard(error: error, primaryButtonAction: { model.error = nil })
			case let .serverSettings(error):
				ErrorPanelCard(error: error, primaryButtonAction: { model.error = nil })
			case let .session(error):
				ErrorPanelCard(error: error, primaryButtonAction: { model.error = nil })
			}
		}
		.toolbar {
			#if os(macOS)
				ToolbarItem(placement: .primaryAction) {
					Button("Done") {
						dismiss()
					}
				}
			#else
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") {
						dismiss()
					}
				}
			#endif
		}
	}

	var modulesSection: some View {
		Section("Modules") {
			ForEach(modules.modules) { module in
				NavigationButton(module.rawValue.name) {
					model.destination = .moduleSettings(module)
				}
			}
		}
	}

	var resetSection: some View {
		Section("Reset") {
			Button(role: .destructive) {
				model.destination = nil

				for module in modules {
					module.rawValue.reset()
				}

				dismiss()
			} label: {
				Text("Reset - This is for easy debugging")
			}
		}
	}
}

extension SettingsListView {
	@Observable
	final class Model {
		var destination: Destination?
		var error: Error?

		init() {}

		/// Navigation destinations for the Settings feature.
		@CasePathable
		enum Destination: Hashable {
			case moduleSettings(AppModules.ModuleType)
		}

		/// Modal error presentations for the Settings feature.
		@CasePathable
		enum Error: Hashable, Identifiable {
			case preferences(TorrentPreferences.Error)
			case serverSettings(ServerSettingsError)
			case session(TorrentSession.Error)

			var id: Self { self }
		}
	}
}

#Preview {
	SettingsFlow()
		.environment(TorrentSession(TorrentPreferences(keychain: InMemoryKeychain())))
}
