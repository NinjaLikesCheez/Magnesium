//
//  TorrentListStatusToolbar.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI

struct TorrentListStatusToolbar: ToolbarContent {
	@Environment(TorrentManager.self) private var torrentManager
	@Environment(TorrentPreferences.self) private var preferences
	@Environment(TorrentListView.Model.self) private var model

	@State var showAddTorrentConfirmation = false
	@State var showingLinkInput = false
	@State var showingFileImporter = false
	@State var linkInput = ""

	var body: some ToolbarContent {
		if #available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, *) {
			glassToolbar
		} else {
			oldGrandpaToolbar
		}
	}

	@available(iOS 26, macOS 26, tvOS 26, visionOS 26, *)
	@ToolbarContentBuilder
	var glassToolbar: some ToolbarContent {
		ToolbarItem(placement: .bottomBar) {
			Text("↓ \(torrentManager.totalDownloadSpeed) ↑ \(torrentManager.totalUploadSpeed)")
				.font(.caption)
				.foregroundStyle(.secondary)
				.frame(minWidth: 100)
		}

		ToolbarSpacer(.flexible, placement: .bottomBar)

		ToolbarItemGroup(placement: .bottomBar) {
			TorrentFilterMenu(labels: torrentManager.labels)
				.environment(preferences)

			Button {
				addTorrentAction()
			} label: {
				Image(systemName: "plus")
			}
			.confirmationDialog(
				"Add Torrent",
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
	}

	@ToolbarContentBuilder
	var oldGrandpaToolbar: some ToolbarContent {
		ToolbarItem(placement: .bottomBar) {
			HStack {
				TorrentFilterMenu(labels: torrentManager.labels)
					.environment(preferences)

				Spacer()

				Text("↓ \(torrentManager.totalDownloadSpeed) ↑ \(torrentManager.totalUploadSpeed)")
					.font(.caption)
					.foregroundStyle(.secondary)
					.frame(minWidth: 100)

				Spacer()

				Button {
					addTorrentAction()
				} label: {
					Image(systemName: "plus")
				}
				.confirmationDialog(
					"Add Torrent",
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
		}
	}

	@ViewBuilder
	private var confirmationDialogButtons: some View {
		Button("Add Link") {
			showingLinkInput = true
		}

		Button("Add File") {
			showingFileImporter = true
		}
	}

	@ViewBuilder
	private var alertContent: some View {
		TextField("magnet:?xt=urn:btih:", text: $linkInput)

		Button("Cancel", role: .cancel) {}

		Button("Ok") {
			Task {
				do throws(TorrentClientError) {
					try await torrentManager.addLink(linkInput)
				} catch {
					model.error = .clientError(error)
				}
			}
		}
	}

	private func addTorrentAction() {
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
			do throws(TorrentClientError) {
				try await torrentManager.addLink(string)
			} catch {
				model.error = .clientError(error)
			}
		}
	}

	private func handleFileImporterResult(_ result: Result<[URL], any Error>) {
		switch result {
		case .success(let urls):
			urls
				.forEach { url in
					Task {
						_ = url.startAccessingSecurityScopedResource()
						do throws(TorrentClientError) {
							try await torrentManager.addLink(url.path())
						} catch {
							model.error = .clientError(error)
						}
						url.stopAccessingSecurityScopedResource()
					}
				}
		case .failure(let error):
			model.error = .fileImportError(.init(error.localizedDescription))
		}
	}
}
