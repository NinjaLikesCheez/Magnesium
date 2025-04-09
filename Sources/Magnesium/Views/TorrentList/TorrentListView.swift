import SwiftUI

public struct TorrentListView: View {
	public init() {}

	@Environment(Session.self) private var session: Session
	@Environment(AppPreferences.self) private var preferences: AppPreferences
	@Environment(\.editMode) private var editMode

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
	@State private var showingSettingsView = false
	@State private var showingFilterView = false

	// TODO: this error handling needs a _lot_ of UX love...
	@State private var error: String?
	@State private var selections: Set<String> = []

	private var selectedTorrents: [StandardTorrent] { torrents.filter { selections.contains($0.id) } }

	public var body: some View {
//		let _ = Self._printChanges()
		NavigationStack {
			AutoRefreshingView(every: preferences.autoRefreshInterval) {
				refresh()
			} content: {
				torrentList
			}
			.refreshable {
				refresh()
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
		.searchable(text: $searchQuery)
		.navigationTitle(session.server.name)
		.toolbar {
			settingsToolbarItem
			selectToolbarItem

			if editMode?.wrappedValue.isEditing ?? false {
				TorrentListEditingToolbar()
			} else {
				TorrentListStatusToolbar(
					showingFilterView: $showingFilterView,
					torrents: torrents
				)
			}
		}
		.sheet(isPresented: $showingSettingsView) {
			SettingsView()
		}
		.sheet(isPresented: $showingFilterView) {
			TorrentFilterSettingsView(labels: labels)
				.presentationDetents([.height(400), .medium, .large])
		}
	}

	@ToolbarContentBuilder
	var settingsToolbarItem: some ToolbarContent {
		ToolbarItem(placement: .topBarLeading) {
			Button {
				showingSettingsView = true
			} label: {
				Image(systemName: "gear")
			}
		}
	}

	@ToolbarContentBuilder
	var selectToolbarItem: some ToolbarContent {
		ToolbarItem(placement: .topBarTrailing) {
			EditButton()
		}
	}

	func refresh() {
		Task {
			do {
				let (torrents, labels) = try await session.actionImplementation.refresh()
				error = nil

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
