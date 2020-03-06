@testable import Magnesium
import Transmission
import XCTest

class TransmissionTorrentTests: XCTestCase {
    func test_standardState() {
        let pairs: [(TransmissionTorrent.Status, TorrentState)] = [
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
            let torrent = TransmissionTorrent.mock(status: pair.0)
            XCTAssertEqual(torrent.standardState, pair.1)
        }
    }

    func test_trackerStrings_shouldBeEqualToTrackerHosts() {
        let trackers = [
            Transmission.Tracker(id: 0, host: "udp://tracker.example.com:9000"),
            Transmission.Tracker(id: 0, host: "http://tracker.example.com:9000/announce"),
        ]
        XCTAssertEqual(TransmissionTorrent.mock(trackers: trackers).trackerStrings, trackers.map(\.host))
    }

    func test_label_shouldBeEmpty() {
        XCTAssertTrue(TransmissionTorrent.mock().label.isEmpty)
    }
}
