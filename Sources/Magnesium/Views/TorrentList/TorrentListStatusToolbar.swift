//
//  TorrentListStatusToolbar.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI

struct TorrentListStatusToolbar: ToolbarContent {
	@Environment(TorrentManager.self) private var torrentManager
	@Environment(AppPreferences.self) private var preferences

	@State var showAddTorrentConfirmation = false
	@State var showingLinkInput = false
	@State var showingFileImporter = false
	@State var linkInput = ""

	var body: some ToolbarContent {
		ToolbarItemGroup(placement: .bottomBar) {
			TorrentFilterMenu(labels: torrentManager.labels)
				.environment(preferences)

			Button {
				addTorrentAction()
			} label: {
				Image(systemName: "plus")
			}
			.confirmationDialog("Add Torrent",
				isPresented: $showAddTorrentConfirmation,
				titleVisibility: .visible
			) {
				confirmationDialogButtons
			} message: {
				Text("How would you like to add the torrent?")
			}
			.alert("Enter a URL", isPresented: $showingLinkInput) {
				alertContent
			} message: {
				Text("This can either be a link to a torrent or a magnet link")
			}
			.fileImporter(
				isPresented: $showingFileImporter,
				allowedContentTypes: [.init(filenameExtension: "torrent")!],
				allowsMultipleSelection: true
			) { result in
				handleFileImporterResult(result)
			}
		}

		ToolbarSpacer(.flexible, placement: .bottomBar)

		ToolbarItem(placement: .bottomBar) {
			Text("↓ \(torrentManager.totalDownloadSpeed) ↑ \(torrentManager.totalUploadSpeed)")
				.font(.caption)
				.foregroundStyle(.secondary)
				.frame(minWidth: 100)
		}
	}

	@ViewBuilder
	var confirmationDialogButtons: some View {
		Button("Add Link") {
			showingLinkInput = true
		}

		Button("Add File") {
			showingFileImporter = true
		}
	}

	@ViewBuilder
	var alertContent: some View {
		TextField("magnet:?xt=urn:btih:", text: $linkInput)

		Button("Cancel", role: .cancel) {}

		Button("Ok") {
			Task {
				// TODO: Error handle
				try await torrentManager.addLink(linkInput)
			}
		}
	}

	func addTorrentAction() {
		guard
			preferences.automaticallyLookForMagnetLinks,
			let string = UIPasteboard.general.string,
			let url = URL(string: string),
			url.scheme == "magnet"
		else {
			showAddTorrentConfirmation = true
			return
		}

		Task {
			do {
				try await torrentManager.addLink(string)
			} catch {
				// TODO: Error handle
				showAddTorrentConfirmation = true
			}
		}
	}

	func handleFileImporterResult(_ result: Result<[URL], any Error>) {
		switch result {
		case .success(let urls):
			urls
				.forEach { url in
					Task {
						// TODO: Handle error
						_ = url.startAccessingSecurityScopedResource()
						try await torrentManager.addLink(url.path())
						url.stopAccessingSecurityScopedResource()
					}
				}
		case .failure(let error):
			// TODO: handle error
			print("file import error: \(error)")
		}
	}
}
