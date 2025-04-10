import SwiftUI

public struct SettingsView: View {
	@Environment(Session.self) private var session: Session
	@Environment(\.dismiss) private var dismiss
	@Environment(AppPreferences.self) private var preferences: AppPreferences

	@State private var servers: [Server] = []

	@State private var selectedRefreshInterval: TimeInterval = Current.preferences.autoRefreshInterval

	let automaticallyLookForMagnetLinks = Binding {
		Current.preferences.automaticallyLookForMagnetLinks
	} set: { newValue in
		Current.preferences.automaticallyLookForMagnetLinks = newValue
	}

	public var body: some View {
		NavigationStack {
			List {
				serverSection

				generalSection
			}
			.navigationTitle("Settings")
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") {
						dismiss()
					}
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
				NavigationLink {
					// TODO: When saving this, we don't dismiss properly because in the onboarding we don't use a dismiss action but rather remove the view on a successful save... fix that plz
					switch server.type {
					case .deluge:
						DelugeServerSettingsView(server)
					case .qbittorrent:
						QBittorrentServerSettingsView(server)
					}
				} label: {
					Text(server.name)
				}
			}

			NavigationLink {
				AddServerView()
			} label: {
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
				//				Current.preferences[.autoRefreshInterval] = newValue
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
}

#Preview {
	SettingsView()
		.environment(Session())
}
