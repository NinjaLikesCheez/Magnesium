import SwiftUI

public struct TorrentListView: View {
	public init() {}

	@Environment(Session.self) private var session: Session
	@Environment(AppPreferences.self) private var preferences: AppPreferences

	@State private var _allTorrents: [StandardTorrent] = []
	private var torrents: [StandardTorrent] {
		TorrentMapper
			.map(
				_allTorrents,
				query: searchQuery,
				sortOption: preferences.sortOption,
				filterOptions: preferences.filterOptions
			)
	}
	@State private var labels: [StandardLabel] = []

	@State private var searchQuery: String = ""
	@State private var showingSettings = false
	@State private var showingFilter = false
	@State private var showingAddOptions = false

	// TODO: this error handling needs a _lot_ of UX love...
	@State private var error: String?
	@State private var selections: Set<String> = []
	@State private var editMode: EditMode = .inactive
	@State private var isConfirmingDelete = false

	private var totalUploadSpeed: String {
		Formatters.bytes.string(fromByteCount: torrents.reduce(into: 0) { $0 += $1.uploadRate })
	}

	private var totalDownloadSpeed: String {
		Formatters.bytes.string(fromByteCount: torrents.reduce(into: 0) { $0 += $1.downloadRate })
	}

	private let timer = Timer.publish(every: Current.preferences.autoRefreshInterval, on: .main, in: .common)
		.autoconnect()

	private var selectedTorrents: [StandardTorrent] { torrents.filter { selections.contains($0.id) } }

	public var body: some View {
//		let _ = Self._printChanges()
		NavigationStack {
			AutoRefreshingView(every: preferences.autoRefreshInterval) {
				refresh()
			} content: {
				torrentList
			}
			.overlay {
				if let error {
					ErrorView(message: error, buttonTitle: "Reload Torrents") {
						refresh()
					}
				} else if torrents.isEmpty && !searchQuery.isEmpty {
					ContentUnavailableView.search
				} else if torrents.isEmpty {
					ContentUnavailableView(
						"No Results",
						systemImage: "line.3.horizontal.decrease.circle",
						description: Text("Check the filters or try add a torrent.")
					)
				}
			}
		}
		.environment(session.actionImplementation)
	}

	var torrentList: some View {
		List(torrents, selection: $selections) { torrent in
			// This is done to remove the disclosure indicator cause yes there's no actual way to do that...
			ZStack {
				TorrentListRow(torrent: .init(torrent: torrent))
				NavigationLink(destination: TorrentDetailView(torrent: torrent)) {
					EmptyView()
				}.opacity(0)
			}
		}
		.environment(\.editMode, $editMode)
		.searchable(text: $searchQuery)
		.navigationTitle(session.server.name)
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Button {
					showingSettings = true
				} label: {
					Image(systemName: "gear")
				}
			}

			ToolbarItem(placement: .topBarTrailing) {
				Button(editMode.isEditing ? "Done" : "Select") {
					editMode = editMode.isEditing ? .inactive : .active
				}
				.disabled(torrents.isEmpty)
			}

			ToolbarItem(placement: .bottomBar) {
				if editMode.isEditing {
					editingBarItems
				} else {
					bottomBarItems
				}
			}
		}
		.sheet(isPresented: $showingSettings) {
			SettingsView()
		}
		.sheet(isPresented: $showingFilter) {
			TorrentFilterSettingsView(labels: labels)
				.presentationDetents([.height(400), .medium, .large])
		}
	}

	var editingBarItems: some View {
		HStack {
			Button {
				Task {
					// TODO: error handle
					try await session.actionImplementation.resume(selectedTorrents)
				}
			} label: {
				Image(systemName: "play.circle")
			}

			Spacer()

			Button {
				Task {
					// TODO: error handle
					try await session.actionImplementation.pause(selectedTorrents)
				}
			} label: {
				Image(systemName: "pause.circle")
			}

			Spacer()

			Button {
				isConfirmingDelete = true
			} label: {
				Image(systemName: "trash.circle")
			}
			.confirmationDialog("Remove", isPresented: $isConfirmingDelete) {
				Button("Keep Data") {
					Task {
						// TODO: error handle
						try await session.actionImplementation.remove(selectedTorrents, false)
					}
				}

				Button("Remove Data", role: .destructive) {
					Task {
						// TODO: error handle
						try await session.actionImplementation.remove(selectedTorrents, true)
					}
				}
			}

			Spacer()

			Button {
				// TODO: this
			} label: {
				Image(systemName: "ellipsis.circle")
			}
		}
	}

	var bottomBarItems: some View {
		HStack {
			Button {
				showingFilter = true
			} label: {
				Image(systemName: "line.3.horizontal.decrease.circle")
			}

			Spacer()

			Text(
				"↓ \(totalDownloadSpeed) ↑ \(totalUploadSpeed)"
			)
			.font(.caption)
			.foregroundStyle(.secondary)

			Spacer()

			Menu {
				Button {
					// TODO: Implement file picker
				} label: {
					Text("Add File")
				}
				Button {
					// TODO: Implement link input
				} label: {
					Text("Add Link")
				}
			} label: {
				Image(systemName: "plus")
			}
		}
	}

	func refresh() {
		Task {
			do {
				let (torrents, labels) = try await session.actionImplementation.refresh()

				error = nil
//				self._allTorrents = torrents
				// TODO: this won't be instantly updated if a filter changes....
				self._allTorrents = torrents
				self.labels = labels
			} catch {
				print("Error refreshing torrents: \(error)")
				self.error = error.localizedDescription
			}
		}
	}
}

#Preview {
	TorrentListView()
}
