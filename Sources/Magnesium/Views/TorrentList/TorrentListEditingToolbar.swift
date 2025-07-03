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
		if #available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, *) {
			glassToolbar
		} else {
			oldGrandpaToolbar
		}
	}

	@available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, *)
	@ToolbarContentBuilder
	var glassToolbar: some ToolbarContent {
		ToolbarSpacer(.flexible, placement: .bottomBar)

		ToolbarItemGroup(placement: .bottomBar) {
			playButton
		}

		ToolbarItemGroup(placement: .bottomBar) {
			pauseButton
		}

		ToolbarItemGroup(placement: .bottomBar) {
			deleteButton
		}

		ToolbarItemGroup(placement: .bottomBar) {
			moreButton
		}
	}

	var oldGrandpaToolbar: some ToolbarContent {
		ToolbarItemGroup(placement: .bottomBar) {
			HStack {
				playButton
				Spacer()
				pauseButton
				Spacer()
				deleteButton
				Spacer()
				moreButton
			}
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
				case .delete(let removeData):
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
