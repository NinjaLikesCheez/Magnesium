import Combine
@testable import Magnesium
import XCTest

class TorrentDetailHeaderItemTests: TestCase {
    private var torrent: CurrentValueSubject<StandardTorrent, Never>!
    private var item: TorrentDetailHeaderItem!

    override func setUp() {
        super.setUp()
        torrent = CurrentValueSubject(.mock())
        item = TorrentDetailHeaderItem(torrentSubject: torrent)
    }

    func test_name() throws {
        torrent.send(.mock(name: "name"))
        XCTAssertEqual(try item.name.first().wait().singleValue(), "name")
    }

    func test_label() throws {
        torrent.send(.mock(label: "label"))
        XCTAssertEqual(try item.label.first().wait().singleValue(), "label")
    }

    func test_isActive_withActiveStates_shouldBeTrue() throws {
        for state in [TorrentState.downloading, .seeding] {
            torrent.send(.mock(state: state))
            XCTAssertTrue(try item.isActive.first().wait().singleValue())
        }
    }

    func test_isActive_withInactiveState_shouldBeFalse() throws {
        for state in [TorrentState.paused, .checking, .queued, .error] {
            torrent.send(.mock(state: state))
            XCTAssertFalse(try item.isActive.first().wait().singleValue())
        }
    }

    func test_progress() throws {
        torrent.send(.mock(progress: 0.189))
        XCTAssertEqual(try item.progress.first().wait().singleValue(), 0.189)
    }

    func test_progressColor() throws {
        let pairs: [(TorrentState, UIColor)] = [
            (.downloading, TorrentState.downloading.displayColor),
            (.seeding, TorrentState.seeding.displayColor),
            (.paused, TorrentState.paused.displayColor),
            (.checking, TorrentState.checking.displayColor),
            (.queued, TorrentState.queued.displayColor),
            (.error, TorrentState.error.displayColor),
        ]

        for (state, result) in pairs {
            torrent.send(.mock(state: state))
            XCTAssertEqual(try item.progressColor.first().wait().singleValue(), result, String(describing: state))
        }
    }

    func test_status() throws {
        let pairs: [(TorrentState, String)] = [
            (.downloading, L10n.Torrent.downloadingState),
            (.seeding, L10n.Torrent.seedingState),
            (.paused, L10n.Torrent.pausedState),
            (.checking, L10n.Torrent.checkingState),
            (.queued, L10n.Torrent.queuedState),
            (.error, L10n.Torrent.errorState),
        ]

        for (state, result) in pairs {
            torrent.send(.mock(state: state))
            XCTAssertEqual(
                try item.status.first().wait().singleValue(),
                L10n.Torrent.torrentStatusWithPercentage(
                    status: result,
                    progress: Formatters.percentage(precision: 2).string(for: torrent.value.progress) ?? ""
                )
            )
        }
    }
}
