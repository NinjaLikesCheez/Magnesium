import Deluge
@testable import Magnesium
import XCTest

class DelugeTorrentTests: TestCase {
    override func setUp() {
        super.setUp()
    }

    func test_init_state_shouldMapToExpectedStandardState() {
        let pairs: [(Torrent.State, TorrentState)] = [
            (.downloading, .downloading),
            (.seeding, .seeding),
            (.paused, .paused),
            (.checking, .checking),
            (.queued, .queued),
            (.error, .error),
        ]

        for pair in pairs {
            let torrent = Torrent.mock(state: pair.0)
            let appTorrent = DelugeTorrent(torrent)
            XCTAssertEqual(appTorrent?.standardState, pair.1)
        }
    }

    func test_init_trackers_shouldMapToExpectedTrackerStrings() {
        let trackers = ["udp://tracker.example.com:9000", "http://tracker.example.com:9000/announce"]
        let torrent = Torrent.mock(trackers: trackers.map(Tracker.init(url:)))
        let appTorrent = DelugeTorrent(torrent)
        XCTAssertEqual(appTorrent?.trackerStrings, trackers)
    }
}
