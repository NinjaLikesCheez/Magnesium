//
//  AddTorrentButton.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct AddTorrentButton: View {
	@Environment(TorrentManager.self) private var torrentManager
	@Environment(TorrentPreferences.self) private var preferences
	@Environment(TorrentListView.Model.self) private var model

	@State private var showAddTorrentConfirmation = false
	@State private var showingLinkInput = false
	@State private var showingFileImporter = false
	@State private var linkInput = ""

	var body: some View {
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
			allowedContentTypes: UTType(filenameExtension: "torrent").map { [$0] } ?? [.data],
			allowsMultipleSelection: true
		) { result in
			handleFileImporterResult(result)
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
			Task {
				var failureMessages: [String] = []

				for url in urls {
					guard url.startAccessingSecurityScopedResource() else {
						failureMessages.append("Couldn't access \(url.lastPathComponent)")
						continue
					}
					defer { url.stopAccessingSecurityScopedResource() }

					do throws(TorrentClientError) {
						try await torrentManager.addLink(url.path())
					} catch {
						failureMessages.append("\(url.lastPathComponent): \(error.localizedDescription)")
					}
				}

				if !failureMessages.isEmpty {
					model.error = .fileImportError(.init(failureMessages.joined(separator: "\n")))
				}
			}
		case .failure(let error):
			model.error = .fileImportError(.init(error.localizedDescription))
		}
	}
}
