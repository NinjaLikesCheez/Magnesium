import SwiftUI

public struct TorrentListView: View {
	public init() {}

	@Environment(Session.self) private var session: Session

	@State private var torrents: [StandardTorrent] = []
	@State private var labels: [StandardLabel] = []

	@State private var searchQuery: String = ""
	@State private var showingSettings = false
	@State private var showingFilter = false
	@State private var showingAddOptions = false

	@State private var selectedSortOption: TorrentSortOption = .dateAdded
	@State private var sortDirection: TorrentSortOption.Direction = .descending
	@State private var selectedStates: Set<TorrentState> = Set(TorrentState.allCases)
	@State private var selectedLabels: Set<StandardLabel> = []

	private var totalUploadSpeed: String {
		Formatters.bytes.string(fromByteCount: torrents.reduce(into: 0) { $0 += $1.uploadRate })
	}

	private var totalDownloadSpeed: String {
		Formatters.bytes.string(fromByteCount: torrents.reduce(into: 0) { $0 += $1.downloadRate })
	}

	private let timer = Timer.publish(every: Current.preferences[.autoRefreshInterval], on: .main, in: .common)
		.autoconnect()

	public var body: some View {
		NavigationStack {
			AutoRefreshingView {
				refresh()
			} content: {
				torrentList
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

						ToolbarItem(placement: .bottomBar) {
							bottomBarItems
						}
					}
					.sheet(isPresented: $showingSettings) {
						SettingsView()
					}
					.popover(isPresented: $showingFilter) {
						TorrentFilterView(
							labels: labels,
							selectedSortOption: $selectedSortOption,
							sortDirection: $sortDirection,
							selectedStates: $selectedStates,
							selectedLabels: $selectedLabels
						)
					}
			}
		}
		.environment(session.actionImplementation)
	}

	var torrentList: some View {
		List(torrents) { torrent in
			// This is done to remove the disclosure indicator cause yes there's no actual way to do that...
			ZStack {
				TorrentListRow(torrent: .init(torrent: torrent))
				NavigationLink(destination: TorrentDetailView(torrent: torrent)) {
					EmptyView()
				}.opacity(0)
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
				self.torrents = TorrentMapper.map(torrents, query: searchQuery)
				self.labels = labels
				if labels.count > 0 && selectedLabels.isEmpty {
					// TODO: rework this cause it's hacky...
					selectedLabels = Set(labels)
				}
			} catch {
				print("Error refreshing torrents: \(error)")
			}
		}
	}
}

#Preview {
	TorrentListView()
}
