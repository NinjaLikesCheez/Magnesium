import SwiftUI

public struct TorrentListView: View {
	@Environment(Session.self) private var session: Session
	@Environment(AppPreferences.self) private var preferences: AppPreferences
	@Environment(TorrentListRouter.self) private var router
	@Environment(TorrentManager.self) var torrentManager
	@Environment(\.userInterfaceIdiom) var userInterfaceIdiom

	@State private var searchQuery: String = ""
	@State private var showAddTorrentConfirmation = false
	@State private var showingFileImporter = false
	@State private var showingLinkInput = false
	@State private var linkInput = ""
	@State private var editMode: EditMode = .inactive

	// TODO: this error handling needs a _lot_ of UX love...
	@State var error: String? = nil
	@State private var editingSelections: Set<String> = []

	@Binding var selections: Set<String>

	var selectedTorrents: Set<StandardTorrent> {
		Set(torrentManager.torrents.filter { selections.contains($0.id) })
	}

	var filteredTorrents: [StandardTorrent] {
		TorrentMapper.map(
			torrentManager.torrents,
			query: searchQuery,
			sortOption: preferences.sortOption,
			filterOptions: preferences.filterOptions
		)
	}

	public var body: some View {
		let _ = Self._printChanges()
		torrentList
			.environment(\.editMode, $editMode)
			.refreshable {
				refresh()
			}
			.onAppear {
				refresh()
			}
			.searchable(text: $searchQuery)
			.navigationTitle(session.server?.name ?? "Torrents")
			.toolbar {
				selectToolbarItem

				if editMode.isEditing {
					TorrentListEditingToolbar(
						selectedTorrents: selectedTorrents,
						error: $error
					)
				} else {
					TorrentListStatusToolbar(
						torrents: filteredTorrents,
						labels: torrentManager.labels,
						showAddTorrentConfirmation: $showAddTorrentConfirmation
					)
				}
			}
			.confirmationDialog("Add Torrent", isPresented: $showAddTorrentConfirmation, titleVisibility: .visible) {
				Button {
					showingLinkInput = true
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
		.overlay {
			if let error {
				ErrorView(message: error, buttonTitle: "Reload Torrents") {
					refresh()
				}
			} else if filteredTorrents.isEmpty && !searchQuery.isEmpty {
				ContentUnavailableView.search
			} else if filteredTorrents.isEmpty {
				ContentUnavailableView(
					"No Results",
					systemImage: "line.3.horizontal.decrease.circle",
					description: Text("Check the filters or try add a torrent.")
				)
			}
		}
	}

	var torrentList: some View {
		List(filteredTorrents, selection: $selections) { torrent in
			HStack {
				TorrentListRow(torrent: .init(torrent: torrent))
			}
			// this is required for the tap gesture to cover the whole row
			.contentShape(Rectangle())
			.onTapGesture {
				if editMode.isEditing {
					selections.insert(torrent.id)
				} else {
					#if os(iOS)
					if userInterfaceIdiom == .phone  {
						router.push(.detail(torrent))
					} else {
						selections = [torrent.id]

					}
					#else
					selections = [torrent.id]
					#endif
				}
			}
		}
	}

	@ToolbarContentBuilder
	var selectToolbarItem: some ToolbarContent {
		ToolbarItem(placement: .topBarTrailing) {
			// EditButton()
			// ^ This doesn't work... because Apple are a small scale start up that can't possibly be expected to make working software
			Button(editMode.isEditing ? "Done" : "Select") {
				withAnimation {
					editMode = editMode.isEditing ? .inactive : .active
				}
			}
		}
	}

	func refresh() {
		Task {
			do {
				try await torrentManager.refresh()
			} catch {
				print("Error refreshing torrents with the torrent manager: \(error)")
			}
		}
	}
}

#Preview {
	@Previewable
	@State var torrents = [StandardTorrent]()
	@Previewable
	@State var labels = [StandardLabel]()
	@Previewable
	@State var searchQuery = ""
	@Previewable
	@State var selections = Set<String>()
	@Previewable
	@State var error: String?


	TorrentListView(selections: $selections)
}

