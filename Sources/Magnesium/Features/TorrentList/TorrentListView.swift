import SwiftUI

public struct TorrentListView: View {
	@Environment(Session.self) private var session: Session
	@Environment(TorrentListRouter.self) private var router
	@Environment(TorrentManager.self) var torrentManager
	@Environment(\.userInterfaceIdiom) var userInterfaceIdiom

	// TODO: this error handling needs a _lot_ of UX love...
	@State var error: String? = nil
	@State private var editingSelections: Set<String> = []

	@Binding var selections: Set<StandardTorrent>
	@Binding var editMode: EditMode

	public var body: some View {
		let _ = Self._printChanges()
		@Bindable var torrentManager = torrentManager

		torrentList
			.environment(\.editMode, $editMode)
			.refreshable { refresh() }
			.onAppear { refresh() }
			.searchable(text: $torrentManager.searchQuery)
			.navigationTitle(session.server?.name ?? "Torrents")
			.overlay {
				if let error {
					ErrorView(message: error, buttonTitle: "Reload Torrents") {
						refresh()
					}
				} else if torrentManager.filteredTorrents.isEmpty && !torrentManager.searchQuery.isEmpty {
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
					.tag(torrent)
			}
			// this is required for the tap gesture to cover the whole row
			.contentShape(Rectangle())
			.onTapGesture {
				if editMode.isEditing {
					selections.insert(torrent)
				} else {
					if userInterfaceIdiom == .pad || userInterfaceIdiom == .mac  {
						selections = [torrent]
					} else {
						router.push(.detail(torrent))
					}
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
	@State var selections = Set<StandardTorrent>()
	@Previewable
	@State var error: String?

	@Previewable
	@State var editMode: EditMode = .inactive


	TorrentListView(selections: $selections, editMode: $editMode)
}

