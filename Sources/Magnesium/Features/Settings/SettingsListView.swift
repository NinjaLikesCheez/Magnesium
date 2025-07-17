import SwiftUI

public struct SettingsListView: View {
	@Environment(Session.self) private var session: Session
	@Environment(AppPreferences.self) private var preferences: AppPreferences
	@Environment(SettingsRouter.self) var router

	@State private var servers: [Server] = []

	@State private var selectedRefreshInterval: TimeInterval = Current.preferences.autoRefreshInterval

	let automaticallyLookForMagnetLinks = Binding {
		Current.preferences.automaticallyLookForMagnetLinks
	} set: { newValue in
		Current.preferences.automaticallyLookForMagnetLinks = newValue
	}

	public var body: some View {
		List {
			serverSection

			generalSection

			resetSection
		}
		.navigationTitle("Settings")
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button("Done") {
					router.dismissSheet(withParent: true)
				}
			}
		}
		.onAppear {
			do {
				servers = try Current.preferences.getServers()
			} catch {
				print("Error getting servers: \(error)")
			}
		}
	}

	var serverSection: some View {
		Section("Servers") {
			ForEach(servers) { server in
				NavigationLink(value: SettingsDestinations.editServer(server)) {
					Text(server.name)
				}
			}

			NavigationLink(value: SettingsDestinations.addAServer) {
				Text("Add Server")
			}
		}
	}

	var generalSection: some View {
		Section("General") {
			Picker(
				"Refresh Interval",
				selection: $selectedRefreshInterval
			) {
				Text("Never").tag(0.0)
				Text("2 seconds").tag(2.0)
				Text("5 seconds").tag(5.0)
				Text("10 seconds").tag(10.0)
				Text("30 seconds").tag(30.0)
				Text("1 minute").tag(60.0)
				Text("5 minutes").tag(300.0)
			}
			.onChange(of: selectedRefreshInterval) { oldValue, newValue in
				preferences.autoRefreshInterval = newValue
			}

			// TODO: model settings in such a way that we can switch on them here and make adding a new setting UI typesafe

			Toggle("Automatically detect magnet links", isOn: automaticallyLookForMagnetLinks)
			Button {
				Task {
					// Create the URL that deep links to your app's custom settings.
					if let url = URL(string: UIApplication.openSettingsURLString) {
						// Ask the system to open that URL.
						await UIApplication.shared.open(url)
					}
				}
			} label: {
				Text("Change system prompt behaviour")
			}
		}
	}

	var resetSection: some View {
		Section("Reset") {
			Button(role: .destructive) {
				router.reset(withParent: true)
				preferences.reset()
				session.reset()
			} label: {
				Text("Reset - This is for easy debugging")
			}
		}
	}
}

#Preview {
	SettingsFlow(settingsRouter: .init())
		.environment(Session(AppPreferences(keychain: InMemoryKeychain())))
}
