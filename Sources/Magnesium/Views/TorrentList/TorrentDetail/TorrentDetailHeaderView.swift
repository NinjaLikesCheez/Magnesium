import SwiftUI
import Torrent

struct TorrentDetailHeaderView: View {
	@Environment(TorrentManager.self) var torrentManager
	@Environment(TorrentListRouter.self) private var router

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
				do throws(TorrentClientError) {
					torrent.isActive
						? try await torrentManager.pause([torrent]) : try await torrentManager.resume([torrent])
				} catch {
					router.presentError(.clientError(error))
				}
			}
		} label: {
			Image(systemName: torrent.isActive ? "pause.fill" : "play.fill")
				.frame(maxWidth: .infinity)
		}
		.backport.glassButtonStyle()
	}

	var removeButton: some View {
		Button {
			showingRemoveConfirmation = true
		} label: {
			Image(systemName: "trash.fill")
				.foregroundStyle(.red)
				.frame(maxWidth: .infinity)
		}
		.backport.glassButtonStyle()
		.confirmationDialog(
			"Remove Torrent",
			isPresented: $showingRemoveConfirmation,
			titleVisibility: .visible
		) {
			Button("Remove Torrent", role: .destructive) {
				Task {
					do throws(TorrentClientError) {
						try await torrentManager.delete([torrent], removeData: false)
						router.pop()
					} catch {
						router.presentError(.clientError(error))
					}
				}
			}

			Button("Remove Torrent and Data", role: .destructive) {
				Task {
					do throws(TorrentClientError) {
						try await torrentManager.delete([torrent], removeData: true)
						router.pop()
					} catch {
						router.presentError(.clientError(error))
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
				do throws(TorrentClientError) {
					let paths = try await torrentManager.paths(for: torrent)
					UIPasteboard.general.string = torrent.downloadPath + "/" + paths[0]
				} catch {
					router.presentError(.clientError(error))
				}
			}
		} label: {
			HStack {
				Image(systemName: "document.on.document")
				Text(L10n.Screen.TorrentInfo.copyFilePath)
			}
			.frame(maxWidth: .infinity)
		}
		.backport.glassButtonStyle()
	}
}
