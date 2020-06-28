@testable import Magnesium
import Transmission
import XCTest

class TransmissionTorrentTests: TestCase {
    override func setUp() {
        super.setUp()
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
            let torrent = StandardTorrent(.mock(status: pair.0))
            XCTAssertEqual(torrent?.state, pair.1)
        }
    }

    func test_init_trackers_shouldMapToExpectedTrackerStrings() {
        let trackers = [
            Tracker(id: 0, host: "udp://tracker.example.com:9000"),
            Tracker(id: 0, host: "http://tracker.example.com:9000/announce"),
        ]
        let torrent = StandardTorrent(.mock(trackers: trackers))
        XCTAssertEqual(torrent?.trackers, trackers.map(\.host))
    }

    func test_init_downloaded_shouldEqualUncheckedPlusValid() {
        let torrent = StandardTorrent(.mock(bytesUnchecked: 1000, bytesValid: 2000))
        XCTAssertEqual(torrent?.downloaded, 3000)
    }
}
