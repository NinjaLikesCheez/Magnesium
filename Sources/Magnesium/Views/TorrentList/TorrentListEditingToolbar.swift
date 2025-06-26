//
//  TorrentListEditingToolbar.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI

struct TorrentListEditingToolbar: ToolbarContent {
	@Environment(TorrentManager.self) private var torrentManager

	@State private var isConfirmingDelete = false
	let selectedTorrents: Set<StandardTorrent>

	var body: some ToolbarContent {
		ToolbarItemGroup(placement: .bottomBar) {
			playButton
		}

		ToolbarSpacer(.flexible, placement: .bottomBar)

		ToolbarItemGroup(placement: .bottomBar) {
			pauseButton
		}

		ToolbarSpacer(.flexible, placement: .bottomBar)

		ToolbarItemGroup(placement: .bottomBar) {
			deleteButton
		}

		ToolbarSpacer(.flexible, placement: .bottomBar)

		ToolbarItemGroup(placement: .bottomBar) {
			moreButton
		}
	}

	var playButton: some View {
		Button {
			perform(.resume)
		} label: {
			Image(systemName: "play")
		}
	}

	var pauseButton: some View {
		Button {
			perform(.pause)
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
				perform(.delete(removeData: false))
			}

			Button("Remove Data", role: .destructive) {
				perform(.delete(removeData: true))
			}
		}
	}

	var moreButton: some View {
		Button {
			// TODO: this
			perform(.more)
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

	func perform(_ action: EditingToolbarAction) {
		Task {
			do {
				switch action {
				case .resume:
					try await torrentManager.resume(Array(selectedTorrents))
				case .pause:
					try await torrentManager.pause(Array(selectedTorrents))
				case let .delete(removeData):
					try await torrentManager.delete(Array(selectedTorrents), removeData: removeData)
				case .more:
					print("TODO")
				}
			} catch {
				print("Error performing toolbar action: \(error.localizedDescription)")
//				self.error = error.localizedDescription
			}
		}
	}
}
