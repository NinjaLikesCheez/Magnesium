import SonarrCore
import SonarrSession
import SwiftUI
import SwiftUINavigation

struct SonarrSeriesListView: View {
	@Environment(SonarrSession.self) private var session: SonarrSession
	@Environment(SonarrSeriesListFlow.Model.self) private var model

	@State private var series: [StandardSeries] = []
	@State private var isLoading = false

	var body: some View {
		List(series) { series in
			SonarrSeriesRow(series: series)
		}
		.refreshable { await refresh() }
		.task { await refresh() }
		.navigationTitle(session.server?.name ?? "Series")
		.overlay {
			if series.isEmpty && isLoading {
				ProgressView()
			} else if series.isEmpty {
				ContentUnavailableView(
					"No Series",
					systemImage: "tv",
					description: Text("Series added to Sonarr will show up here.")
				)
			}
		}
	}

	private func refresh() async {
		isLoading = true
		defer { isLoading = false }

		do throws(SonarrClientError) {
			series = try await session.client.refresh()
		} catch {
			model.error = .clientError(error)
		}
	}
}
