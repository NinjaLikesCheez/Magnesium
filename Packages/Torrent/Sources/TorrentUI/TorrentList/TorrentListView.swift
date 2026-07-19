import SwiftUI
import SwiftUINavigation

public struct TorrentListView: View {
	@Environment(TorrentSession.self) private var session: TorrentSession
	@Environment(Model.self) private var model
	@Environment(TorrentManager.self) var manager
	@Environment(\.userInterfaceIdiom) var userInterfaceIdiom

	@State private var editingSelections: Set<String> = []
	@State private var isSearchActive = false

	@Binding var selections: Set<String>
	@Binding var editMode: EditMode

	var selectedTorrents: Set<StandardTorrent> {
		Set(manager.filteredTorrents.filter { selections.contains($0.id) })
	}

	public var body: some View {
		//		let _ = Self._printChanges()
		@Bindable var manager = manager

		torrentList
			.environment(\.editMode, $editMode)
			.refreshable { refresh() }
			.onAppear { refresh() }
			// Must sit inside the searchable scope, so before .searchable in the chain.
			.background { SearchActivityReader(isSearchActive: $isSearchActive) }
			.searchable(text: $manager.searchQuery)
			.safeAreaBar(edge: .bottom) { editingActionsBar }
			.navigationTitle(session.server?.name ?? "Torrents")
			.overlay {
				if manager.filteredTorrents.isEmpty && !manager.searchQuery.isEmpty {
					ContentUnavailableView.search
				} else if manager.filteredTorrents.isEmpty {
					ContentUnavailableView(
						"No Results",
						systemImage: "line.3.horizontal.decrease.circle",
						description: Text("Check the filters or try add a torrent.")
					)
				}
			}
	}

	var torrentList: some View {
		List(manager.filteredTorrents, selection: $selections) { torrent in
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
						model.destination = .detail(torrent)
					}
				}
			}
		}
	}

	/// Keeps the multi-select actions reachable while searching: the expanded search field takes over
	/// the entire bottom bar, hiding TorrentListEditingToolbar, so float the same actions above it.
	/// The searchQuery check covers the field staying expanded with committed text after focus is lost.
	@ViewBuilder
	var editingActionsBar: some View {
		if editMode.isEditing && (isSearchActive || !manager.searchQuery.isEmpty) {
			HStack(spacing: 28) {
				TorrentListEditingActions(editMode: $editMode, selectedTorrents: selectedTorrents)
			}
			.padding(.horizontal, 24)
			.padding(.vertical, 14)
			.glassEffect()
			// Match the monochrome icons of the bottom-bar toolbar these actions mirror.
			.tint(.primary)
		}
	}

	func refresh() {
		Task {
			do throws(TorrentClientError) {
				try await manager.refresh()
			} catch {
				model.error = .clientError(error)
			}
		}
	}
}

/// Mirrors the `isSearching` environment value (only readable inside a searchable scope) out to a
/// binding, so the view that owns `.searchable` can react to search becoming active.
private struct SearchActivityReader: View {
	@Environment(\.isSearching) private var isSearching

	@Binding var isSearchActive: Bool

	var body: some View {
		Color.clear
			.onChange(of: isSearching, initial: true) { _, newValue in
				isSearchActive = newValue
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

extension TorrentListView {
	@Observable
	public final class Model {
		public var error: Error?
		public var destination: Destination?

		public init() {}

		/// Stack-navigation targets for the TorrentList feature.
		@CasePathable
		public enum Destination: Hashable {
			/// Navigate to the detailed view of a specific torrent
			case detail(StandardTorrent)
		}

		/// Modal error presentations for the TorrentList feature.
		@CasePathable
		public enum Error: Hashable {
			case clientError(TorrentClientError)
			case fileImportError(FileImportError)  // fileImport API throws any Error... so manually build it
		}

		/// A file-import failure message. `id` is the message itself since these carry no other identity.
		public struct FileImportError: Hashable, Identifiable {
			public var id: String { message }
			public let message: String

			public init(_ message: String) {
				self.message = message
			}
		}
	}
}
