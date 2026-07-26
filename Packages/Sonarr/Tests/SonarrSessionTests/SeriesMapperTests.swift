import Foundation
import Sonarr
import Testing

@testable import SonarrSession

@Suite
struct SeriesMapperTests {
	@Test
	func mapsFullResource() throws {
		let resource = try decode(
			"""
			{
				"id": 1,
				"title": "Breaking Bad",
				"overview": "A chemistry teacher turns to crime.",
				"monitored": true,
				"statistics": {
					"seasonCount": 5,
					"episodeFileCount": 62,
					"episodeCount": 62,
					"totalEpisodeCount": 62,
					"sizeOnDisk": 0,
					"releaseGroups": [],
					"percentOfEpisodes": 100
				}
			}
			"""
		)

		let series = try #require(SeriesMapper.map(resource))

		#expect(series.id == 1)
		#expect(series.title == "Breaking Bad")
		#expect(series.seasonCount == 5)
		#expect(series.episodeCount == 62)
		#expect(series.episodeFileCount == 62)
		#expect(series.monitored == true)
	}

	@Test
	func returnsNilWithoutID() throws {
		let resource = try decode(#"{"title": "No ID"}"#)
		#expect(SeriesMapper.map(resource) == nil)
	}

	@Test
	func returnsNilWithoutTitle() throws {
		let resource = try decode(#"{"id": 1}"#)
		#expect(SeriesMapper.map(resource) == nil)
	}

	@Test
	func defaultsMissingStatisticsToZero() throws {
		let resource = try decode(#"{"id": 2, "title": "No Stats"}"#)
		let series = try #require(SeriesMapper.map(resource))

		#expect(series.seasonCount == 0)
		#expect(series.episodeCount == 0)
		#expect(series.episodeFileCount == 0)
		#expect(series.monitored == false)
	}

	private func decode(_ json: String) throws -> SeriesResource {
		try JSONDecoder().decode(SeriesResource.self, from: Data(json.utf8))
	}
}
