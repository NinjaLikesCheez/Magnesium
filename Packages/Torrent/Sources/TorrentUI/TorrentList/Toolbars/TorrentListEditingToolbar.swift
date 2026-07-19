//
//  TorrentListEditingToolbar.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI

struct TorrentListEditingToolbar: ToolbarContent {
	@Binding var editMode: EditMode

	let selectedTorrents: Set<StandardTorrent>

	var body: some ToolbarContent {
		ToolbarSpacer(.flexible, placement: .bottomBar)

		ToolbarItemGroup(placement: .bottomBar) {
			TorrentListEditingActions(editMode: $editMode, selectedTorrents: selectedTorrents)
		}
	}
}

/// The multi-select actions, shared between `TorrentListEditingToolbar` and the floating bar
/// `TorrentListView` shows while search is active (the expanded search field replaces the whole
/// bottom bar, which would otherwise make these unreachable mid-search).
struct TorrentListEditingActions: View {
	@Environment(TorrentManager.self) private var torrentManager
	@Environment(TorrentListView.Model.self) var model

	@State private var isConfirmingDelete = false
	@Binding var editMode: EditMode

	let selectedTorrents: Set<StandardTorrent>

	var body: some View {
		playButton
		pauseButton
		deleteButton
		moreButton
	}

	var playButton: some View {
		Button {
			Task {
				try await perform(.resume)
			}
		} label: {
			Image(systemName: "play")
		}
	}

	var pauseButton: some View {
		Button {
			Task {
				try await perform(.pause)
			}
		} label: {
			Image(systemName: "pause")
		}
	}

	var deleteButton: some View {
		Button {
			isConfirmingDelete = true
		} label: {
			Image(systemName: "trash")
		}
		.confirmationDialog("Remove", isPresented: $isConfirmingDelete) {
			Button("Keep Data") {
				Task {
					try await perform(.delete(removeData: false))
				}
			}

			Button("Remove Data", role: .destructive) {
				Task {
					try await perform(.delete(removeData: true))
				}
			}
		}
	}

	var moreButton: some View {
		Button {
			// TODO: this
			Task {
				try await perform(.more)
			}
		} label: {
			Image(systemName: "ellipsis")
		}
	}

	enum EditingToolbarAction {
		case resume
		case pause
		case delete(removeData: Bool)
		case more
	}

	func perform(_ action: EditingToolbarAction) async throws {
		do throws(TorrentClientError) {
			switch action {
			case .resume:
				try await torrentManager.resume(Array(selectedTorrents))
			case .pause:
				try await torrentManager.pause(Array(selectedTorrents))
			case .delete(let removeData):
				try await torrentManager.delete(Array(selectedTorrents), removeData: removeData)
				editMode = .inactive
			case .more:
				// TODO: implement this please
				print("TODO")
			}
		} catch {
			model.error = .clientError(error)
		}
	}
}
