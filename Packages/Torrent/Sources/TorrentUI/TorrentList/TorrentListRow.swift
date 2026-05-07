import SwiftUI

struct TorrentListRow: View {
	var torrent: TorrentListItem

	var body: some View {
		VStack(alignment: .leading) {
			Text(torrent.name)

			if torrent.label != "" {
				HStack {
					Text(torrent.label)
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
			}

			ProgressView(value: torrent.progress)
				.tint(torrent.progressColor)

			VStack {
				HStack {
					Text(torrent.status)
						.font(.subheadline)
						.foregroundStyle(.secondary)

					Spacer()

					Text(torrent.speed)
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}

				HStack {
					Text(torrent.progressText)
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.frame(alignment: .trailing)

					Spacer()

					Text(torrent.ratioOrETA)
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
			}
		}
	}
}
