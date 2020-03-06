import Combine
import CryptoKit
@testable import Magnesium
import XCTest

class TorrentMapperTests: XCTestCase {
    private let preferences = MockPreferences()

    private func getValues(from mapper: TorrentMapper<Int, MockTorrent>) -> [MockTorrent] {
        var values: [MockTorrent]?
        _ = mapper.values.sink { values = $0.map { $0.value } }
        return values!
    }

    func test_sort_withName() {
        let torrents = [
            MockTorrent(name: "B", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "A", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "a", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "C", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
        ]
        let expectedAscending: [String] = [torrents[1].hash, torrents[2].hash].sorted()
            + [torrents[0].hash, torrents[3].hash]
        let expectedDescending: [String] = [torrents[3].hash, torrents[0].hash]
            + [torrents[1].hash, torrents[2].hash].sorted()

        let mapper = TorrentMapper<Int, MockTorrent>(preferences: preferences, query: CurrentValueSubject(nil))
        mapper.update(with: Array(torrents.enumerated()))

        preferences.set(SortOption(property: .name, direction: .ascending), for: PreferenceKeys.sortOption)
        XCTAssertEqual(getValues(from: mapper).map { $0.hash }, expectedAscending)

        preferences.set(SortOption(property: .name, direction: .descending), for: PreferenceKeys.sortOption)
        XCTAssertEqual(getValues(from: mapper).map { $0.hash }, expectedDescending)
    }

    func test_sort_withDateAdded() {
        let date = Date()
        let torrents = [
            MockTorrent(name: "B", dateAdded: date.addingTimeInterval(1), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "A1", dateAdded: date, downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "a2", dateAdded: date, downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "A1", dateAdded: date, downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "C", dateAdded: date.addingTimeInterval(2), downloadRate: 0, uploadRate: 0),
        ]
        let expectedAscending = [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash, torrents[0].hash, torrents[4].hash]
        let expectedDescending = [torrents[4].hash, torrents[0].hash]
            + [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash]

        let mapper = TorrentMapper<Int, MockTorrent>(preferences: preferences, query: CurrentValueSubject(nil))
        mapper.update(with: Array(torrents.enumerated()))

        preferences.set(SortOption(property: .dateAdded, direction: .ascending), for: PreferenceKeys.sortOption)
        XCTAssertEqual(getValues(from: mapper).map { $0.hash }, expectedAscending)

        preferences.set(SortOption(property: .dateAdded, direction: .descending), for: PreferenceKeys.sortOption)
        XCTAssertEqual(getValues(from: mapper).map { $0.hash }, expectedDescending)
    }

    func test_sort_withDownloadSpeed() {
        let torrents = [
            MockTorrent(name: "B", dateAdded: Date(), downloadRate: 1, uploadRate: 0),
            MockTorrent(name: "A1", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "a2", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "A1", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "C", dateAdded: Date(), downloadRate: 2, uploadRate: 0),
        ]
        let expectedAscending = [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash, torrents[0].hash, torrents[4].hash]
        let expectedDescending = [torrents[4].hash, torrents[0].hash]
            + [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash]

        let mapper = TorrentMapper<Int, MockTorrent>(preferences: preferences, query: CurrentValueSubject(nil))
        mapper.update(with: Array(torrents.enumerated()))

        preferences.set(SortOption(property: .downloadSpeed, direction: .ascending), for: PreferenceKeys.sortOption)
        XCTAssertEqual(getValues(from: mapper).map { $0.hash }, expectedAscending)

        preferences.set(SortOption(property: .downloadSpeed, direction: .descending), for: PreferenceKeys.sortOption)
        XCTAssertEqual(getValues(from: mapper).map { $0.hash }, expectedDescending)
    }

    func test_sort_withUploadSpeed() {
        let torrents = [
            MockTorrent(name: "B", dateAdded: Date(), downloadRate: 0, uploadRate: 1),
            MockTorrent(name: "A1", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "a2", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "A1", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "C", dateAdded: Date(), downloadRate: 0, uploadRate: 2),
        ]
        let expectedAscending = [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash, torrents[0].hash, torrents[4].hash]
        let expectedDescending = [torrents[4].hash, torrents[0].hash]
            + [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash]

        let mapper = TorrentMapper<Int, MockTorrent>(preferences: preferences, query: CurrentValueSubject(nil))
        mapper.update(with: Array(torrents.enumerated()))

        preferences.set(SortOption(property: .uploadSpeed, direction: .ascending), for: PreferenceKeys.sortOption)
        XCTAssertEqual(getValues(from: mapper).map { $0.hash }, expectedAscending)

        preferences.set(SortOption(property: .uploadSpeed, direction: .descending), for: PreferenceKeys.sortOption)
        XCTAssertEqual(getValues(from: mapper).map { $0.hash }, expectedDescending)
    }

    func test_filter_withState() {
        let torrents = [
            MockTorrent(standardState: .downloading, dateAdded: Date(timeIntervalSinceNow: 0)),
            MockTorrent(standardState: .seeding, dateAdded: Date(timeIntervalSinceNow: -1)),
            MockTorrent(standardState: .error, dateAdded: Date(timeIntervalSinceNow: -2)),
            MockTorrent(standardState: .downloading, dateAdded: Date(timeIntervalSinceNow: -3)),
        ]
        let expected = [torrents[0].hash, torrents[3].hash]

        let mapper = TorrentMapper<Int, MockTorrent>(preferences: preferences, query: CurrentValueSubject(nil))
        mapper.update(with: Array(torrents.enumerated()))

        preferences.set(FilterOptions(state: .downloading), for: PreferenceKeys.filterOptions)
        XCTAssertEqual(getValues(from: mapper).map { $0.hash }, expected)
    }

    func test_filter_withLabel() {
        let torrents = [
            MockTorrent(dateAdded: Date(timeIntervalSinceNow: 0), label: "test"),
            MockTorrent(dateAdded: Date(timeIntervalSinceNow: -1), label: ""),
            MockTorrent(dateAdded: Date(timeIntervalSinceNow: -2), label: "test"),
        ]
        let expected = [torrents[0].hash, torrents[2].hash]

        let mapper = TorrentMapper<Int, MockTorrent>(preferences: preferences, query: CurrentValueSubject(nil))
        mapper.update(with: Array(torrents.enumerated()))

        preferences.set(FilterOptions(label: "test"), for: PreferenceKeys.filterOptions)
        XCTAssertEqual(getValues(from: mapper).map { $0.hash }, expected)
    }

    func test_search_shouldConsiderSpaceAndDotEqual() {
        let torrents = [
            MockTorrent(name: "test.torrent", dateAdded: Date(timeIntervalSinceNow: 0)),
            MockTorrent(name: "torrent.test", dateAdded: Date(timeIntervalSinceNow: -1)),
            MockTorrent(name: "test torrent", dateAdded: Date(timeIntervalSinceNow: -2)),
            MockTorrent(name: "test/torrent", dateAdded: Date(timeIntervalSinceNow: -3)),
        ]
        let expected = [torrents[0].hash, torrents[2].hash]

        let mapper = TorrentMapper<Int, MockTorrent>(
            preferences: preferences,
            query: CurrentValueSubject("test tor")
        )
        mapper.update(with: Array(torrents.enumerated()))
        XCTAssertEqual(getValues(from: mapper).map { $0.hash }, expected)
    }

    func test_search_shouldBeCaseInsensitive() {
        let torrents = [
            MockTorrent(name: "test.torrent", dateAdded: Date(timeIntervalSinceNow: 0)),
            MockTorrent(name: "torrent.test", dateAdded: Date(timeIntervalSinceNow: -1)),
            MockTorrent(name: "TEST torrent", dateAdded: Date(timeIntervalSinceNow: -2)),
            MockTorrent(name: "test/torrent", dateAdded: Date(timeIntervalSinceNow: -3)),
        ]
        let expected = [torrents[0].hash, torrents[2].hash]

        let mapper = TorrentMapper<Int, MockTorrent>(
            preferences: preferences,
            query: CurrentValueSubject("TEST TOR")
        )
        mapper.update(with: Array(torrents.enumerated()))
        XCTAssertEqual(getValues(from: mapper).map { $0.hash }, expected)
    }
}
