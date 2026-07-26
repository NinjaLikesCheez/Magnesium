import Common
import CommonUI
import SonarrCore
import SonarrSession
import SwiftUI
import SwiftUINavigation

struct SonarrSettingsListView: View {
	@Environment(SonarrSettingsFlow.Model.self) private var model
	@Environment(SonarrSession.self) private var session: SonarrSession
	@Environment(SonarrPreferences.self) private var preferences: SonarrPreferences

	@State private var server: SonarrServer?

	var body: some View {
		@Bindable var model = model

		List {
			serverSection

			resetSection
		}
		.navigationDestination(item: $model.destination.addOrEditServer) { _ in
			AddSonarrServerView(existing: server, onError: { model.error = .addServerError($0) })
				.environment(preferences)
		}
		.panel(item: $model.error) { error in
			ErrorPanelCard(
				error: error,
				primaryButtonAction: { model.error = nil }
			)
		}
		.navigationTitle("Sonarr Settings")
		.onAppear {
			refresh()
		}
	}

	private func refresh() {
		do throws(SonarrPreferences.Error) {
			server = try preferences.getServer()
		} catch {
			model.error = .preferences(error)
		}
	}

	var serverSection: some View {
		Section("Server") {
			if let server {
				NavigationButton(server.name) {
					model.destination = .addOrEditServer
				}
			} else {
				Button {
					model.destination = .addOrEditServer
				} label: {
					Text("Add Server")
				}
			}
		}
	}

	var resetSection: some View {
		Section("Reset") {
			Button(role: .destructive) {
				model.destination = nil
				preferences.reset()
				session.reset()
			} label: {
				Text("Reset - This is for easy debugging")
			}
		}
	}
}
