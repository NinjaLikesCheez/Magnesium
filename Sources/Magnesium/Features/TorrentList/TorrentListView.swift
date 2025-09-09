import SwiftUI

public struct TorrentListView: View {
	@Environment(Session.self) private var session: Session
	@Environment(TorrentListRouter.self) private var router
	@Environment(TorrentManager.self) var torrentManager
	@Environment(\.userInterfaceIdiom) var userInterfaceIdiom

	@State private var editingSelections: Set<String> = []

	@Binding var selections: Set<String>
	@Binding var editMode: EditMode

	var selectedTorrents: Set<StandardTorrent> {
		Set(torrentManager.filteredTorrents.filter { selections.contains($0.id) })
	}

	public var body: some View {
		let _ = Self._printChanges()
		@Bindable var torrentManager = torrentManager

		torrentList
			.environment(\.editMode, $editMode)
			.refreshable { refresh() }
			.onAppear { refresh() }
			.searchable(text: $torrentManager.searchQuery)
			// If we ever migrate to a tab bar... I want that nice ass search bar...
			.searchToolbarBehavior(.minimize)
			.navigationTitle(session.server?.name ?? "Torrents")
			.overlay {
				if torrentManager.filteredTorrents.isEmpty && !torrentManager.searchQuery.isEmpty {
					ContentUnavailableView.search
				} else if torrentManager.filteredTorrents.isEmpty {
					ContentUnavailableView(
						"No Results",
						systemImage: "line.3.horizontal.decrease.circle",
						description: Text("Check the filters or try add a torrent.")
					)
				}
			}
	}

	var torrentList: some View {
		List(torrentManager.filteredTorrents, selection: $selections) { torrent in
			HStack {
				TorrentListRow(torrent: .init(torrent: torrent))
					// This type **must** match whatever the selection's element is
					.tag(torrent.id)
			}
			// this is required for the tap gesture to cover the whole row
			.contentShape(Rectangle())
			.onTapGesture {
				if editMode.isEditing {
					selections.insert(torrent.id)
				} else {
					if userInterfaceIdiom == .pad || userInterfaceIdiom == .mac {
						selections = [torrent.id]
					} else {
						router.push(.detail(torrent))
					}
				}
			}
		}
	}

	func refresh() {
		Task {
			do throws(TorrentClientError) {
				try await torrentManager.refresh()
			} catch {
				router.presentError(.clientError(error))
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

	@Previewable
	@State var editMode: EditMode = .inactive

	TorrentListView(selections: $selections, editMode: $editMode)
}
