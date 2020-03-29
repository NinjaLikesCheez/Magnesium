import Combine
@testable import Magnesium
import XCTest

class TorrentDetailHeaderItemTests: TestCase {
    private var torrent: CurrentValueSubject<MockTorrent, Never>!
    private var item: TorrentDetailHeaderItem!

    override func setUp() {
        super.setUp()
        torrent = CurrentValueSubject(MockTorrent())
        item = TorrentDetailHeaderItem(torrent: torrent)
    }

    func test_name() {
        torrent.send(MockTorrent(name: "name"))
        XCTAssertEqual(item.name.first().wait(), "name")
    }

    func test_label() {
        torrent.send(MockTorrent(label: "label"))
        XCTAssertEqual(item.label.first().wait(), "label")
    }

    func test_isActive_withActiveStates_shouldBeTrue() throws {
        for state in [TorrentState.downloading, .seeding] {
            torrent.send(MockTorrent(standardState: state))
            XCTAssertTrue(item.isActive.first().wait())
        }
    }

    func test_isActive_withInactiveState_shouldBeFalse() {
        for state in [TorrentState.paused, .checking, .queued, .error] {
            torrent.send(MockTorrent(standardState: state))
            XCTAssertFalse(item.isActive.first().wait())
        }
    }

    func test_progress() {
        torrent.send(MockTorrent(progress: 0.189_838))
        XCTAssertEqual(item.progress.first().wait(), 0.189_838)
    }

    func test_progressColor() {
        let pairs: [(TorrentState, UIColor)] = [
            (.downloading, TorrentState.downloading.displayColor),
            (.seeding, TorrentState.seeding.displayColor),
            (.paused, TorrentState.paused.displayColor),
            (.checking, TorrentState.checking.displayColor),
            (.queued, TorrentState.queued.displayColor),
            (.error, TorrentState.error.displayColor),
        ]

        for (state, result) in pairs {
            torrent.send(MockTorrent(standardState: state))
            XCTAssertEqual(item.progressColor.first().wait(), result, String(describing: state))
        }
    }

    func test_status() {
        let pairs: [(TorrentState, String)] = [
            (.downloading, "Downloading"),
            (.seeding, "Seeding"),
            (.paused, "Paused"),
            (.checking, "Checking"),
            (.queued, "Queued"),
            (.error, "Error"),
        ]

        for (state, result) in pairs {
            torrent.send(MockTorrent(standardState: state))
            XCTAssertEqual(item.status.first().wait(), "\(result) (0.00%)")
        }
    }
}
