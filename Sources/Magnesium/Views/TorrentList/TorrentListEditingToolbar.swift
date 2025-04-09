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

	var body: some ToolbarContent {
		ToolbarItem(placement: .bottomBar) {
				editingBarItems
		}
	}

	var playButton: some View {
		Button {
			Task {
				// TODO: error handle
//					try await session.actionImplementation.resume(selectedTorrents)
			}
		} label: {
			Image(systemName: "play.circle")
		}
	}

	var editingBarItems: some View {
		HStack {
			playButton

			Spacer()
			
			Button {
				Task {
					// TODO: error handle
//					try await session.actionImplementation.pause(selectedTorrents)
				}
			} label: {
				Image(systemName: "pause.circle")
			}
			
			Spacer()
			
			Button {
				isConfirmingDelete = true
			} label: {
				Image(systemName: "trash.circle")
			}
			.confirmationDialog("Remove", isPresented: $isConfirmingDelete) {
				Button("Keep Data") {
					Task {
						// TODO: error handle
//						try await session.actionImplementation.remove(selectedTorrents, false)
					}
				}
				
				Button("Remove Data", role: .destructive) {
					Task {
						// TODO: error handle
//						try await session.actionImplementation.remove(selectedTorrents, true)
					}
				}
			}
			
			Spacer()
			
			Button {
				// TODO: this
			} label: {
				Image(systemName: "ellipsis.circle")
			}
		}
	}
}
