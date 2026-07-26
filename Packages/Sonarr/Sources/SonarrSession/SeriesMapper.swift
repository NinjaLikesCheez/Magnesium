import Sonarr
import SonarrCore

enum SeriesMapper {
	static func map(_ resource: SeriesResource) -> StandardSeries? {
		guard let id = resource.id, let title = resource.title else { return nil }

		let statistics = resource.statistics

		return StandardSeries(
			id: id,
			title: title,
			overview: resource.overview,
			seasonCount: statistics?.seasonCount ?? 0,
			episodeCount: statistics?.episodeCount ?? 0,
			episodeFileCount: statistics?.episodeFileCount ?? 0,
			monitored: resource.monitored ?? false
		)
	}
}
