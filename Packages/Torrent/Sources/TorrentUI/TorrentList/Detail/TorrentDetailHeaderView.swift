import SwiftUI

extension TorrentDetailView {
	struct HeaderView: View {
		@Environment(TorrentManager.self) var torrentManager
		@Environment(TorrentDetailView.Model.self) private var model
		@Environment(\.dismiss) var dismiss

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
						model.error = .clientError(error)
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
							dismiss()
						} catch {
							model.error = .clientError(error)
						}
					}
				}

				Button("Remove Torrent and Data", role: .destructive) {
					Task {
						do throws(TorrentClientError) {
							try await torrentManager.delete([torrent], removeData: true)
							dismiss()
						} catch {
							model.error = .clientError(error)
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
						model.error = .clientError(error)
					}
				}
			} label: {
				HStack {
					Image(systemName: "document.on.document")
					Text("Copy File Path")
				}
				.frame(maxWidth: .infinity)
			}
			.backport.glassButtonStyle()
		}
	}
}
