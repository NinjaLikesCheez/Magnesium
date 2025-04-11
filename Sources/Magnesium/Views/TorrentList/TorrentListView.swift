import SwiftUI

enum SheetDestination: Identifiable {
	var id: Self { self }

	case filter
	case settings
}

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
	@State private var sheetDestination: SheetDestination?
	@State private var showAddTorrentConfirmation = false
	@State private var showingFileImporter = false
	@State private var showingLinkInput = false
	@State private var linkInput = ""

	// TODO: this error handling needs a _lot_ of UX love...
	@State private var error: String?
	@State private var selections: Set<String> = []

	private var selectedTorrents: [StandardTorrent] { torrents.filter { selections.contains($0.id) } }

	public var body: some View {
//		let _ = Self._printChanges()
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

	var torrentList: some View {
		List(torrents, selection: $selections) { torrent in
			// This is done to remove the disclosure indicator cause yes there's no actual way to do that...
			ZStack {
				TorrentListRow(torrent: .init(torrent: torrent))
				NavigationLink {
					TorrentDetailView(torrent: torrent)
						.environment(session.actionImplementation)
				} label: {
					EmptyView()
				}.opacity(0)
			}
		}
		.refreshable {
			refresh()
		}
		.searchable(text: $searchQuery)
		.navigationTitle(session.server.name)
		.toolbar {
			settingsToolbarItem
			selectToolbarItem

			// TODO: this doesn't correctly respond to changes, fix general architecture
			if editMode?.wrappedValue.isEditing ?? false {
				TorrentListEditingToolbar(
					selectedTorrents: selectedTorrents,
					error: $error
				)
			} else {
				TorrentListStatusToolbar(
					torrents: torrents,
					sheetDestination: $sheetDestination,
					showAddTorrentConfirmation: $showAddTorrentConfirmation
				)
			}
		}
		.sheet(item: $sheetDestination) { sheetDestination in
			switch sheetDestination {
			case .filter:
				TorrentFilterSettingsView(labels: labels)
					.presentationDetents([.height(400), .medium, .large])
			case .settings:
				SettingsView()
			}
		}
		.confirmationDialog("Add Torrent", isPresented: $showAddTorrentConfirmation, titleVisibility: .visible) {
			Button {
				
			} label: {
				Text("Add Link")
			}

			Button {
				showingFileImporter = true
			} label: {
				Text("Add File")
			}
		} message: {
			Text("How would you like to add the torrent?")
		}
		.fileImporter(
			isPresented: $showingFileImporter,
			allowedContentTypes: [.init(filenameExtension: "torrent")!],
			allowsMultipleSelection: true
		) { result in
			switch result {
			case .success(let urls):
				urls
					.forEach { url in
						Task {
							// TODO: Handle error
							_ = url.startAccessingSecurityScopedResource()
							try await session.actionImplementation.addLink(url.path())
							url.stopAccessingSecurityScopedResource()
						}
					}
				refresh() // force a refresh to show newly added torrents
			case .failure(let error):
				// TODO: handle error
				print("file import error: \(error)")
			}
		}
		.alert("Enter a URL", isPresented: $showingLinkInput) {
			TextField("magnet:?xt=urn:btih:", text: $linkInput)
			Button("Cancel", role: .cancel) {}
			Button {
				Task {
					// TODO: Error handle
					try await session.actionImplementation.addLink(linkInput)
					refresh()
				}
			} label: {
				Text("OK")
			}
		} message: {
			Text("This can either be a link to a torrent or a magnet link")
		}
	}

	@ToolbarContentBuilder
	var settingsToolbarItem: some ToolbarContent {
		ToolbarItem(placement: .topBarLeading) {
			Button {
				sheetDestination = .settings
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
