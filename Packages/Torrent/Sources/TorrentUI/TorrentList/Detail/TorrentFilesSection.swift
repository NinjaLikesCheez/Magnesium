//
//  TorrentFilesSection.swift
//  Magnesium
//
//  Created by ninji on 10/04/2025.
//

import SwiftUI
import Common

struct TorrentFilesSection: View {
	@Environment(TorrentManager.self) var manager
	@Environment(TorrentDetailView.Model.self) private var model

	var torrent: StandardTorrent
	@State private var files: [StandardTorrentFile] = []
	// TODO: add priority changing

	var body: some View {
		Section {
			ForEach(files) { file in
				HStack {
					VStack(alignment: .leading) {
						Text("\(file.name)")
						Text("\(file.size.formatted(Formatters.bytes))) (\(file.progress.formatted(Formatters.percentage)))")
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
				}
			}
		} header: {
			Text("Files")
				.font(.headline)
		}
		.onAppear {
			Task {
				do throws(TorrentClientError) {
					files = try await manager.refreshFiles(for: torrent)
				} catch {
					model.error = .clientError(error)
				}
			}
		}
	}
}
