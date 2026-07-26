import Sonarr
import SonarrCore

/// Wraps `sonarr-swift`'s `Sonarr` client, translating wire types to `StandardSeries` and
/// `Sonarr.Error` to `SonarrClientError`.
public final class SonarrAPIClient: SonarrClient {
	private let client: Sonarr

	public init(client: Sonarr) {
		self.client = client
	}

	public func refresh() async throws(SonarrClientError) -> [StandardSeries] {
		do {
			let series = try await client.request(.series())
			return series.compactMap(SeriesMapper.map)
		} catch {
			throw .sonarr(error)
		}
	}

	public func setMonitored(_ monitored: Bool, for series: StandardSeries) async throws(SonarrClientError) {
		do {
			let existing = try await client.request(.series(id: series.id))
			let updated = SeriesResource(
				id: existing.id,
				title: existing.title,
				alternateTitles: existing.alternateTitles,
				sortTitle: existing.sortTitle,
				status: existing.status,
				ended: existing.ended,
				profileName: existing.profileName,
				overview: existing.overview,
				nextAiring: existing.nextAiring,
				previousAiring: existing.previousAiring,
				network: existing.network,
				airTime: existing.airTime,
				images: existing.images,
				originalLanguage: existing.originalLanguage,
				remotePoster: existing.remotePoster,
				seasons: existing.seasons,
				year: existing.year,
				path: existing.path,
				qualityProfileId: existing.qualityProfileId,
				seasonFolder: existing.seasonFolder,
				monitored: monitored,
				monitorNewItems: existing.monitorNewItems,
				useSceneNumbering: existing.useSceneNumbering,
				runtime: existing.runtime,
				tvdbId: existing.tvdbId,
				tvRageId: existing.tvRageId,
				tvMazeId: existing.tvMazeId,
				tmdbId: existing.tmdbId,
				firstAired: existing.firstAired,
				lastAired: existing.lastAired,
				seriesType: existing.seriesType,
				cleanTitle: existing.cleanTitle,
				imdbId: existing.imdbId,
				titleSlug: existing.titleSlug,
				rootFolderPath: existing.rootFolderPath,
				folder: existing.folder,
				certification: existing.certification,
				genres: existing.genres,
				tags: existing.tags,
				added: existing.added,
				addOptions: existing.addOptions,
				ratings: existing.ratings,
				statistics: existing.statistics,
				episodesChanged: existing.episodesChanged
			)
			_ = try await client.request(.updateSeries(id: series.id, updated))
		} catch {
			throw .sonarr(error)
		}
	}

	public func triggerSearch(for series: StandardSeries) async throws(SonarrClientError) {
		do {
			_ = try await client.request(.seriesSearch(seriesId: series.id))
		} catch {
			throw .sonarr(error)
		}
	}

	public func remove(_ series: StandardSeries, deleteFiles: Bool) async throws(SonarrClientError) {
		do {
			_ = try await client.request(.deleteSeries(id: series.id, deleteFiles: deleteFiles))
		} catch {
			throw .sonarr(error)
		}
	}
}
