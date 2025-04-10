//
//  TorrentListEditingToolbar.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI

struct TorrentListEditingToolbar: ToolbarContent {
	@Environment(Session.self) private var session: Session

	@State private var isConfirmingDelete = false
	let selectedTorrents: [StandardTorrent]

	@Binding var error: String?

	var body: some ToolbarContent {
		ToolbarItem(placement: .bottomBar) {
			editingBarItems
		}
	}

	var playButton: some View {
		Button {
			Task {
				do {
					try await session.actionImplementation.resume(selectedTorrents)
				} catch {
					self.error = error.localizedDescription
				}
			}
		} label: {
			Image(systemName: "play.circle")
		}
	}

	var pauseButton: some View {
		Button {
			Task {
				do {
					try await session.actionImplementation.pause(selectedTorrents)
				} catch {
					self.error = error.localizedDescription
				}
			}
		} label: {
			Image(systemName: "pause.circle")
		}
	}

	var deleteButton: some View {
		Button {
			isConfirmingDelete = true
		} label: {
			Image(systemName: "trash.circle")
		}
		.confirmationDialog("Remove", isPresented: $isConfirmingDelete) {
			Button("Keep Data") {
				Task {
					do {
						try await session.actionImplementation.remove(selectedTorrents, false)
					} catch {
						self.error = error.localizedDescription
					}
				}
			}

			Button("Remove Data", role: .destructive) {
				Task {
					do {
						try await session.actionImplementation.remove(selectedTorrents, true)
					} catch {
						self.error = error.localizedDescription
					}
				}
			}
		}
	}

	var moreButton: some View {
		Button {
			// TODO: this
		} label: {
			Image(systemName: "ellipsis.circle")
		}
	}

	var editingBarItems: some View {
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
