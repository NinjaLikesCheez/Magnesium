import CommonUI
import SwiftUI
import SwiftUINavigation

struct TorrentDetailView: View {
	@Environment(TorrentManager.self) private var torrentManager
	@State private var model = Model()
	@State private var isPerformingOverflowAction = false

	var torrent: StandardTorrent

	var body: some View {
		@Bindable var model = model

		List {
			Section {
				HeaderView(torrent: torrent)
			}

			TorrentInformationSection(torrent: torrent)

			TorrentTrackerSection(torrent: torrent)

			TorrentFilesSection(torrent: torrent)
		}
		.buttonStyle(BorderlessButtonStyle())
		.navigationTitle("Info")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			overflowMenu
		}
		.panel(item: $model.error.clientError) { error in
			ErrorPanelCard(
				error: error,
				primaryButtonAction: { model.error = nil }
			)
		}
		.islandToast(item: $model.toast) { toast in
			switch toast {
			case .updateTrackers:
				IslandToastCard(
					title: "Trackers updated",
					subtitle: "Placeholder subtitle",
					role: .success
				)
			}
		}
		.environment(model)
	}

	@ToolbarContentBuilder
	var overflowMenu: some ToolbarContent {
		#if os(macOS)
			ToolbarItem(placement: .primaryAction) {
				overflowMenuContent
			}
		#else
			ToolbarItem(placement: .topBarTrailing) {
				overflowMenuContent
			}
		#endif
	}

	var overflowMenuContent: some View {
		Menu {
			Button {
				perform(.verify)
			} label: {
				Label("Force Recheck", systemImage: "checkmark.shield")
			}

			Button {
				perform(.updateTrackers)
			} label: {
				Label("Update Tracker", systemImage: "antenna.radiowaves.left.and.right")
			}
		} label: {
			Image(systemName: "ellipsis")
		}
		.disabled(isPerformingOverflowAction)
	}

	enum OverflowAction {
		case verify
		case updateTrackers
	}

	private func perform(_ action: OverflowAction) {
		guard !isPerformingOverflowAction else { return }
		isPerformingOverflowAction = true

		Task {
			defer { isPerformingOverflowAction = false }

			do throws(TorrentClientError) {
				switch action {
				case .verify:
					try await torrentManager.verify([torrent])
				case .updateTrackers:
					try await torrentManager.updateTrackers([torrent])
					model.toast = .updateTrackers
				}
			} catch {
				model.error = .clientError(error)
			}
		}
	}
}

extension TorrentDetailView {
	/// Navigation + presentation state for the TorrentDetail screen.
	@Observable
	public final class Model {
		public var destination: Destination?
		public var error: Error?
		public var toast: Toast?

		public init() {}

		/// Stack-navigation targets for the TorrentDetail screen. Currently a leaf with nothing to
		/// push, but kept alongside `Error` for consistency with `TorrentListModel`'s shape.
		@CasePathable
		public enum Destination: Hashable {}

		/// Modal error presentations for the TorrentDetail screen.
		@CasePathable
		public enum Error: Hashable {
			case clientError(TorrentClientError)
		}

		@CasePathable
		public enum Toast: Hashable {
			case updateTrackers
		}
	}
}
