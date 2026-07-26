import SonarrCore
import SwiftUI

struct SonarrSeriesRow: View {
	let series: StandardSeries

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack {
				Text(series.title)
					.font(.headline)

				Spacer()

				if !series.monitored {
					Image(systemName: "eye.slash")
						.foregroundStyle(.secondary)
				}
			}

			Text("\(series.seasonCount) seasons · \(series.episodeFileCount)/\(series.episodeCount) episodes")
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
	}
}
