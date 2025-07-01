import SwiftUI

// TODO: this doesn't refresh automatically (i.e. if you pause)
struct TorrentDetailHeaderView: View {
	@Environment(TorrentManager.self) var torrentManager
	@Environment(\.dismiss) private var dismiss
	var torrent: StandardTorrent

	@State private var showingRemoveConfirmation = false

	var body: some View {
		VStack(alignment: .leading) {
			Text(torrent.name)
				.font(.headline)
				.fontWeight(.bold)

			if torrent.label != "" {
				Text(torrent.label)
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}

			ProgressView(value: torrent.progress)
				.tint(torrent.state.progressColor)

			Text(torrent.state.localizedString)
				.font(.subheadline)
				.foregroundStyle(.secondary)

			buttons
		}
	}

	var buttons: some View {
		VStack {
			HStack {
				pauseResumeButton

				removeButton
			}

			copyFilePathButton
		}
	}

	var pauseResumeButton: some View {
		Button {
			Task {
				do {
					torrent.isActive
					? try await torrentManager.pause([torrent]) : try await torrentManager.resume([torrent])
				} catch {
					print("Error pausing/resuming torrent: \(error)")
				}
			}
		} label: {
			Image(systemName: torrent.isActive ? "pause.fill" : "play.fill")
				.frame(maxWidth: .infinity)
		}
		.backgroundStyle(.gray)
		.buttonStyle(.bordered)
	}

	var removeButton: some View {
		Button {
			showingRemoveConfirmation = true
		} label: {
			Image(systemName: "trash.fill")
				.foregroundStyle(.red)
				.frame(maxWidth: .infinity)
		}
		.backgroundStyle(.gray)
		.buttonStyle(.bordered)
		.confirmationDialog(
			"Remove Torrent",
			isPresented: $showingRemoveConfirmation,
			titleVisibility: .visible
		) {
			Button("Remove Torrent", role: .destructive) {
				Task {
					do {
						try await torrentManager.delete([torrent], removeData: false)
						dismiss()
					} catch {
						print("Error: Failed to remove torrent: \(error)")
					}
				}
			}
			Button("Remove Torrent and Data", role: .destructive) {
				Task {
					do {
						try await torrentManager.delete([torrent], removeData: true)
						dismiss()
					} catch {
						print("Error: Failed to remove torrent and data")
					}
				}
			}
			Button("Cancel", role: .cancel) {}
		} message: {
			Text("Choose how to remove this torrent")
		}
	}

	var copyFilePathButton: some View {
		Button {
			Task {
				do {
					let paths = try await torrentManager.paths(for: torrent)
					UIPasteboard.general.string = torrent.downloadPath + "/" + paths[0]
				} catch {
					print("Error copying file path: \(error)")
				}
			}
		} label: {
			HStack {
				Image(systemName: "document.on.document")
				Text(L10n.Screen.TorrentInfo.copyFilePath)
			}
			.frame(maxWidth: .infinity)
		}
		.backgroundStyle(.gray)
		.buttonStyle(.bordered)
	}
}
