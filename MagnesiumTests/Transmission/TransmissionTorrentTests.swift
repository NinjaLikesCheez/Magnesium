@testable import Magnesium
import Transmission
import XCTest

class TransmissionTorrentTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Current = .mock
    }

    func test_init_state_shouldMapToExpectedStandardState() {
        let pairs: [(Torrent.Status, TorrentState)] = [
            (.downloading, .downloading),
            (.seeding, .seeding),
            (.paused, .paused),
            (.checking, .checking),
            (.checkQueued, .queued),
            (.downloadQueued, .queued),
            (.seedQueued, .queued),
            (.isolated, .error),
        ]

        for pair in pairs {
            let torrent = Torrent.mock(status: pair.0)
            let appTorrent = TransmissionTorrent(torrent)
            XCTAssertEqual(appTorrent?.standardState, pair.1)
        }
    }

    func test_init_trackers_shouldMapToExpectedTrackerStrings() {
        let trackers = [
            Tracker(id: 0, host: "udp://tracker.example.com:9000"),
            Tracker(id: 0, host: "http://tracker.example.com:9000/announce"),
        ]
        let torrent = Torrent.mock(trackers: trackers)
        let appTorrent = TransmissionTorrent(torrent)
        XCTAssertEqual(appTorrent?.trackerStrings, trackers.map(\.host))
    }

    func test_label_shouldBeEmpty() {
        XCTAssertTrue(TransmissionTorrent.mock().label.isEmpty)
    }
}
