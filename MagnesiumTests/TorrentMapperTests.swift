import Combine
import CryptoKit
@testable import Magnesium
import Preferences
import XCTest

class TorrentMapperTests: TestCase {
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
    }

    func test_sort_withName() {
        let torrents = [
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 0, name: "B", uploadRate: 0),
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 0, name: "A", uploadRate: 0),
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 0, name: "a", uploadRate: 0),
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 0, name: "C", uploadRate: 0),
        ]
        let expectedAscending: [String] = [torrents[1].hash, torrents[2].hash].sorted()
            + [torrents[0].hash, torrents[3].hash]
        let expectedDescending: [String] = [torrents[3].hash, torrents[0].hash]
            + [torrents[1].hash, torrents[2].hash].sorted()

        let mapper = TorrentMapper(query: CurrentValueSubject(nil))
        mapper.update(with: torrents)

        preferences[.sortOption] = SortOption(property: .name, direction: .ascending)
        XCTAssertEqual(mapper.values.map(\.value.hash), expectedAscending)

        preferences[.sortOption] = SortOption(property: .name, direction: .descending)
        XCTAssertEqual(mapper.values.map(\.value.hash), expectedDescending)
    }

    func test_sort_withDateAdded() {
        let date = Date()
        let torrents = [
            StandardTorrent.mock(dateAdded: date.addingTimeInterval(1), downloadRate: 0, name: "B", uploadRate: 0),
            StandardTorrent.mock(dateAdded: date, downloadRate: 0, name: "A1", uploadRate: 0),
            StandardTorrent.mock(dateAdded: date, downloadRate: 0, name: "a2", uploadRate: 0),
            StandardTorrent.mock(dateAdded: date, downloadRate: 0, name: "A1", uploadRate: 0),
            StandardTorrent.mock(dateAdded: date.addingTimeInterval(2), downloadRate: 0, name: "C", uploadRate: 0),
        ]
        let expectedAscending = [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash, torrents[0].hash, torrents[4].hash]
        let expectedDescending = [torrents[4].hash, torrents[0].hash]
            + [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash]

        let mapper = TorrentMapper(query: CurrentValueSubject(nil))
        mapper.update(with: torrents)

        preferences[.sortOption] = SortOption(property: .dateAdded, direction: .ascending)
        XCTAssertEqual(mapper.values.map(\.value.hash), expectedAscending)

        preferences[.sortOption] = SortOption(property: .dateAdded, direction: .descending)
        XCTAssertEqual(mapper.values.map(\.value.hash), expectedDescending)
    }

    func test_sort_withDownloadSpeed() {
        let torrents = [
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 1, name: "B", uploadRate: 0),
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 0, name: "A1", uploadRate: 0),
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 0, name: "a2", uploadRate: 0),
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 0, name: "A1", uploadRate: 0),
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 2, name: "C", uploadRate: 0),
        ]
        let expectedAscending = [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash, torrents[0].hash, torrents[4].hash]
        let expectedDescending = [torrents[4].hash, torrents[0].hash]
            + [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash]

        let mapper = TorrentMapper(query: CurrentValueSubject(nil))
        mapper.update(with: torrents)

        preferences[.sortOption] = SortOption(property: .downloadSpeed, direction: .ascending)
        XCTAssertEqual(mapper.values.map(\.value.hash), expectedAscending)

        preferences[.sortOption] = SortOption(property: .downloadSpeed, direction: .descending)
        XCTAssertEqual(mapper.values.map(\.value.hash), expectedDescending)
    }

    func test_sort_withUploadSpeed() {
        let torrents = [
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 0, name: "B", uploadRate: 1),
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 0, name: "A1", uploadRate: 0),
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 0, name: "a2", uploadRate: 0),
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 0, name: "A1", uploadRate: 0),
            StandardTorrent.mock(dateAdded: Date(), downloadRate: 0, name: "C", uploadRate: 2),
        ]
        let expectedAscending = [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash, torrents[0].hash, torrents[4].hash]
        let expectedDescending = [torrents[4].hash, torrents[0].hash]
            + [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash]

        let mapper = TorrentMapper(query: CurrentValueSubject(nil))
        mapper.update(with: torrents)

        preferences[.sortOption] = SortOption(property: .uploadSpeed, direction: .ascending)
        XCTAssertEqual(mapper.values.map(\.value.hash), expectedAscending)

        preferences[.sortOption] = SortOption(property: .uploadSpeed, direction: .descending)
        XCTAssertEqual(mapper.values.map(\.value.hash), expectedDescending)
    }

    func test_filter_withState() {
        let torrents = [
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: 0), state: .downloading),
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: -1), state: .seeding),
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: -2), state: .error),
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: -3), state: .downloading),
        ]
        let expected = [torrents[0].hash, torrents[3].hash]

        let mapper = TorrentMapper(query: CurrentValueSubject(nil))
        mapper.update(with: torrents)

        preferences[.filterOptions] = FilterOptions(state: .downloading)
        XCTAssertEqual(mapper.values.map(\.value.hash), expected)
    }

    func test_filter_withLabel() {
        let torrents = [
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: 0), label: "test"),
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: -1), label: ""),
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: -2), label: "test"),
        ]
        let expected = [torrents[0].hash, torrents[2].hash]

        let mapper = TorrentMapper(query: CurrentValueSubject(nil))
        mapper.update(with: torrents)

        preferences[.filterOptions] = FilterOptions(label: "test")
        XCTAssertEqual(mapper.values.map(\.value.hash), expected)
    }

    func test_search_shouldConsiderSpaceAndDotEqual() {
        let torrents = [
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: 0), name: "test.torrent"),
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: -1), name: "torrent.test"),
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: -2), name: "test torrent"),
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: -3), name: "test/torrent"),
        ]
        let expected = [torrents[0].hash, torrents[2].hash]

        let mapper = TorrentMapper(query: CurrentValueSubject("test tor"))
        mapper.update(with: torrents)
        XCTAssertEqual(mapper.values.map(\.value.hash), expected)
    }

    func test_search_shouldBeCaseInsensitive() {
        let torrents = [
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: 0), name: "test.torrent"),
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: -1), name: "torrent.test"),
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: -2), name: "TEST torrent"),
            StandardTorrent.mock(dateAdded: Date(timeIntervalSinceNow: -3), name: "test/torrent"),
        ]
        let expected = [torrents[0].hash, torrents[2].hash]

        let mapper = TorrentMapper(query: CurrentValueSubject("TEST TOR"))
        mapper.update(with: torrents)
        XCTAssertEqual(mapper.values.map(\.value.hash), expected)
    }
}
