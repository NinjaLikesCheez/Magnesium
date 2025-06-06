import SwiftUI

public struct TorrentListView: View {
	@Environment(Session.self) private var session: Session
	@Environment(AppPreferences.self) private var preferences: AppPreferences
	@Environment(Router.self) private var router

	@Binding var torrents: [StandardTorrent]
	@Binding var labels: [StandardLabel]
	@Binding var searchQuery: String
	@State private var showAddTorrentConfirmation = false
	@State private var showingFileImporter = false
	@State private var showingLinkInput = false
	@State private var linkInput = ""
	@State private var editMode: EditMode = .inactive

	// TODO: this error handling needs a _lot_ of UX love...
	@Binding var error: String?
	@State private var editingSelections: Set<String> = []

	@Binding var selections: Set<String>

	var selectedTorrents: Set<StandardTorrent> {
		Set(torrents.filter { selections.contains($0.id) })
	}

	public var body: some View {
//		let _ = Self._printChanges()
		AutoRefreshingView(every: preferences.autoRefreshInterval) {
			refresh()
		} content: {
			torrentList
				.environment(\.editMode, $editMode)
				.refreshable {
					refresh()
				}
				.searchable(text: $searchQuery)
				.navigationTitle(session.server?.name ?? "Torrents")
				.toolbar {
					settingsToolbarItem

					selectToolbarItem

					if editMode.isEditing {
						TorrentListEditingToolbar(
							selectedTorrents: selectedTorrents,
							error: $error
						)
					} else {
						TorrentListStatusToolbar(
							torrents: $torrents,
							labels: $labels,
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
			HStack {
				TorrentListRow(torrent: .init(torrent: torrent))
			}
			// this is required for the tap gesture to cover the whole row
			.contentShape(Rectangle())
			.onTapGesture {
				if editMode.isEditing {
					selections.insert(torrent.id)
				} else {
					selections = [torrent.id]
				}
			}
		}
	}

	@ToolbarContentBuilder
	var settingsToolbarItem: some ToolbarContent {
		ToolbarItem(placement: .topBarLeading) {
			Button {
				router.present(TorrentListCoordinator.Sheets.settings)
			} label: {
				Image(systemName: "gear")
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
				let (torrents, labels) = try await session.actionImplementation.refresh()
				error = nil

				self.torrents = TorrentMapper
					.map(
						torrents,
						query: searchQuery,
						sortOption: preferences.sortOption,
						filterOptions: preferences.filterOptions
					)
				self.labels = labels
			} catch {
				print("Error refreshing torrents: \(error)")
				self.error = error.localizedDescription
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


	TorrentListView(torrents: $torrents, labels: $labels, searchQuery: $searchQuery, error: $error, selections: $selections)
}
