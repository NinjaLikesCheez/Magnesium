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

	//	var generalSection: some View {
	//		Section("General") {
	//			Picker(
	//				"Refresh Interval",
	//				selection: $selectedRefreshInterval
	//			) {
	//				Text("Never").tag(0.0)
	//				Text("2 seconds").tag(2.0)
	//				Text("5 seconds").tag(5.0)
	//				Text("10 seconds").tag(10.0)
	//				Text("30 seconds").tag(30.0)
	//				Text("1 minute").tag(60.0)
	//				Text("5 minutes").tag(300.0)
	//			}
	//			.onChange(of: selectedRefreshInterval) { oldValue, newValue in
	//				preferences.autoRefreshInterval = newValue
	//			}
	//
	//			// TODO: model settings in such a way that we can switch on them here and make adding a new setting UI typesafe
	//
	//			Toggle("Automatically detect magnet links", isOn: automaticallyLookForMagnetLinks)
	//
	//			#if !os(macOS)
	//				Button {
	//					Task {
	//						// Create the URL that deep links to your app's custom settings.
	//						if let url = URL(string: UIApplication.openSettingsURLString) {
	//							// Ask the system to open that URL.
	//							await UIApplication.shared.open(url)
	//						}
	//					}
	//				} label: {
	//					Text("Change system prompt behaviour")
	//				}
	//			#endif
	//		}
	//	}

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
