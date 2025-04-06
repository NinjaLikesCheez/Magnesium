import SwiftUI

public struct SettingsView: View {
	@Environment(Session.self) private var session: Session
	@Environment(\.dismiss) private var dismiss

	@State private var servers: [Server] = []

	@State private var selectedRefreshInterval: TimeInterval = Current.preferences[.autoRefreshInterval]

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
				Current.preferences[.autoRefreshInterval] = newValue
			}
		}
	}
}

#Preview {
	SettingsView()
		.environment(Session())
}
