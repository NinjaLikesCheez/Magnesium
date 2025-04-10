//
//  AddFileView.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI

struct AddTorrentView: View {
	@Environment(Session.self) private var session
	@Environment(\.dismiss) private var dismiss

	@State private var urlString: String = ""
	@State private var showingFileImporter = false
	@State private var showingMagnetInput = false

	var body: some View {
		NavigationStack {
			List {
				addSection
				pasteSection
			}
			.onAppear {
				guard Current.preferences.automaticallyLookForMagnetLinks, let string = UIPasteboard.general.string else {
					return
				}

				if string.starts(with: "magnet:") {
					urlString = string
				}
			}
			// TODO: Add a UTI type for torrent: https://developer.apple.com/documentation/uniformtypeidentifiers
			.fileImporter(
				isPresented: $showingFileImporter,
				allowedContentTypes: [.init(filenameExtension: "torrent")!],
				allowsMultipleSelection: true
			) { result in
				switch result {
				case .success(let urls):
					urls
						.forEach { url in
							Task {
								// TODO: Handle error
								_ = url.startAccessingSecurityScopedResource()
								try await session.actionImplementation.addLink(url.path())
								url.stopAccessingSecurityScopedResource()
							}
						}

					dismiss()
				case .failure(let error):
					// TODO: handle error
					print("file import error: \(error)")
				}
			}
			.alert("Enter a URL", isPresented: $showingMagnetInput) {
				TextField("magnet:?xt=urn:btih:", text: $urlString)
				Button("Cancel", role: .cancel) {}
				Button("OK", action: addURL)
			} message: {
				Text("This can either be a link to a torrent or a magnet link")
			}
		}
	}

	func addURL() {
		guard !urlString.isEmpty else {
			// TODO: error handle
			print("invalid url")
			return
		}

		Task {
			try await session.actionImplementation.addLink(urlString)
			dismiss()
		}
	}

	var addSection: some View {
		Section {
			Button {
				showingMagnetInput = true
			} label: {
				HStack {
					Image(systemName: "link")
					Text("Add Link")
				}
			}

			Button {
				showingFileImporter = true
			} label: {
				HStack {
					Image(systemName: "document")
					Text("Add File")
				}
			}
		}
	}

	var pasteSection: some View {
		Section {
			if !urlString.isEmpty {
				Button {
					Task {
						// TODO: handle error
						try await session.actionImplementation.addLink(urlString)
						dismiss()
					}
				} label: {
					HStack {
						Image(systemName: "document.on.clipboard")
						Text("Paste magnet link")
					}
				}
			}
		}
	}
}

