//
//  TorrentFilesSection.swift
//  Magnesium
//
//  Created by ninji on 10/04/2025.
//

import SwiftUI

struct TorrentFilesSection: View {
	@Environment(TorrentManager.self) var manager

	var torrent: StandardTorrent
	@State private var files: [StandardTorrentFile] = []
	// TODO: add priority changing

	var body: some View {
		Section {
			ForEach(files) { file in
				HStack {
					VStack(alignment: .leading) {
						Text("\(file.name)")
						Text("\(Formatters.bytes.string(fromByteCount: file.size)) (\(Formatters.percentage.string(for: file.progress) ?? "0%"))")
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
				do {
					files = try await manager.refreshFiles(for: torrent)
				} catch {
					print("error fetching file details: \(error)")
				}
			}
		}
	}
}
