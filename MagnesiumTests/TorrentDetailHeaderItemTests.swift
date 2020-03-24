import Combine
@testable import Magnesium
import XCTest

class TorrentDetailHeaderItemTests: XCTestCase {
    private var torrent: CurrentValueSubject<MockTorrent, Never>!
    private var item: TorrentDetailHeaderItem!

    override func setUp() {
        super.setUp()
        Current = .mock
        torrent = CurrentValueSubject(MockTorrent())
        item = TorrentDetailHeaderItem(torrent: torrent)
    }

    func test_name() {
        torrent.send(MockTorrent(name: "name"))
        XCTAssertEqual(item.name.wait().first(), "name")
    }

    func test_label() {
        torrent.send(MockTorrent(label: "label"))
        XCTAssertEqual(item.label.wait().first(), "label")
    }

    func test_isActive_withActiveStates_shouldBeTrue() throws {
        for state in [TorrentState.downloading, .seeding] {
            torrent.send(MockTorrent(standardState: state))
            XCTAssertTrue(item.isActive.wait().first())
        }
    }

    func test_isActive_withInactiveState_shouldBeFalse() {
        for state in [TorrentState.paused, .checking, .queued, .error] {
            torrent.send(MockTorrent(standardState: state))
            XCTAssertFalse(item.isActive.wait().first())
        }
    }

    func test_progress() {
        torrent.send(MockTorrent(progress: 0.189_838))
        XCTAssertEqual(item.progress.wait().first(), 0.189_838)
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
            XCTAssertEqual(item.progressColor.wait().first(), result, String(describing: state))
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
            XCTAssertEqual(item.status.wait().first(), "\(result) (0.00%)")
        }
    }
}
