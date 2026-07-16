import SwiftUI
import CommonUI
import SwiftUINavigation

public struct TorrentSettingsListView: View {
	@Environment(TorrentSession.self) private var session: TorrentSession
	@Environment(TorrentPreferences.self) private var preferences: TorrentPreferences

	@State private var model: Model = .init()
	@State private var servers: [TorrentServer] = []
	@State private var selectedRefreshInterval: TimeInterval = 0

	private var automaticallyLookForMagnetLinks: Binding<Bool> {
		Binding {
			preferences.automaticallyLookForMagnetLinks
		} set: { newValue in
			preferences.automaticallyLookForMagnetLinks = newValue
		}
	}

	public var body: some View {
		List {
			serverSection

			generalSection

			resetSection
		}
		.navigationDestination(item: $model.destination) { destination in
			switch destination {
			case .addAServer:
				AddServerView()
					.environment(preferences)
			case let .editServer(server):
				switch server.type {
				case .deluge:
					EditDelugeServerView(server)
						.environment(model)
						.environment(preferences)
						.environment(session)
				case .qbittorrent:
					fatalError("Not yet implemented")
				}
			}
		}
		.navigationTitle("Torrent Settings")
		.onAppear {
			do throws(TorrentPreferences.Error) {
				servers = try preferences.getServers()
				selectedRefreshInterval = preferences.autoRefreshInterval
			} catch {
				model.error = .preferences(error)
			}
		}
	}

	var serverSection: some View {
		Section("Servers") {
			ForEach(servers) { server in
				NavigationButton(server.name) {
					model.destination = .editServer(server)
				}
			}

			Button {
				model.destination = .addAServer
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
			}

			// TODO: model settings in such a way that we can switch on them here and make adding a new setting UI typesafe

			Toggle("Automatically detect magnet links", isOn: automaticallyLookForMagnetLinks)

			#if !os(macOS)
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
			#endif
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

extension TorrentSettingsListView {
	@Observable
	final class Model {
		var destination: Destination?
		var error: Error?

		init() {}

		/// Stack-navigation targets for the Settings feature. Genuinely multi-level: the list can
		/// push `addAServer`, and `addAServer` itself pushes `addNewServer`.
		@CasePathable
		enum Destination: Hashable {
			/// Navigate to edit an existing server's configuration
			case editServer(TorrentServer)

			/// Navigate to the server selection screen where users can choose which type of server to add
			case addAServer
		}

		/// Modal error presentations for the Settings feature.
		@CasePathable
		enum Error: Hashable, Identifiable {
			case preferences(TorrentPreferences.Error)
			//			case serverSettings(ServerSettingsError)
			//			case session(TorrentSession.Error)

			public var id: Self { self }
		}
	}
}
