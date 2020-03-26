import Combine
@testable import Magnesium
import XCTest

class TorrentListItemTests: XCTestCase {
    private var subject: CurrentValueSubject<MockTorrent, Never>!
    private var item: TorrentListItem!

    override func setUp() {
        super.setUp()
        Current = .mock
        subject = CurrentValueSubject(MockTorrent())
        item = TorrentListItem(torrent: subject)
    }

    func test_identity_shouldBeEqualToHash() {
        let torrent1 = MockTorrent(hash: "A")
        var torrent2 = MockTorrent(hash: "A")
        XCTAssertEqual(
            TorrentListItem(torrent: CurrentValueSubject(torrent1)).id,
            TorrentListItem(torrent: CurrentValueSubject(torrent2)).id
        )

        torrent2.hash = "B"
        XCTAssertNotEqual(
            TorrentListItem(torrent: CurrentValueSubject(torrent1)).id,
            TorrentListItem(torrent: CurrentValueSubject(torrent2)).id
        )
    }

    func test_equality_shouldBeDerivedFromID() {
        let torrent1 = MockTorrent(hash: "A")
        var torrent2 = MockTorrent(hash: "A")
        XCTAssertEqual(
            TorrentListItem(torrent: CurrentValueSubject(torrent1)),
            TorrentListItem(torrent: CurrentValueSubject(torrent2))
        )

        torrent2.hash = "B"
        XCTAssertNotEqual(
            TorrentListItem(torrent: CurrentValueSubject(torrent1)),
            TorrentListItem(torrent: CurrentValueSubject(torrent2))
        )
    }

    func test_hashValue_shouldBeDerivedFromID() {
        let torrent1 = MockTorrent(hash: "A")
        var torrent2 = MockTorrent(hash: "A")
        XCTAssertEqual(
            TorrentListItem(torrent: CurrentValueSubject(torrent1)).hashValue,
            TorrentListItem(torrent: CurrentValueSubject(torrent2)).hashValue
        )

        torrent2.hash = "B"
        XCTAssertNotEqual(
            TorrentListItem(torrent: CurrentValueSubject(torrent1)).hashValue,
            TorrentListItem(torrent: CurrentValueSubject(torrent2)).hashValue
        )
    }

    func test_name() {
        subject.send(MockTorrent(name: "name"))
        XCTAssertEqual(item.name.first().wait(), "name")
    }

    func test_progress() {
        subject.send(MockTorrent(progress: 0.189_838))
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
            subject.send(MockTorrent(standardState: state))
            XCTAssertEqual(item.progressColor.first().wait(), result, String(describing: state))
        }
    }

    func test_state() {
        let pairs: [(TorrentState, String)] = [
            (.downloading, "Downloading"),
            (.seeding, "Seeding"),
            (.paused, "Paused"),
            (.checking, "Checking"),
            (.queued, "Queued"),
            (.error, "Error"),
        ]

        for (state, result) in pairs {
            subject.send(MockTorrent(standardState: state))
            XCTAssertEqual(item.state.first().wait(), result, String(describing: state))
        }
    }

    func test_speed_whenDownloading_shouldContainDownloadAndUploadRate() {
        subject.send(MockTorrent(downloadRate: 1_540_527, uploadRate: 465_158))
        XCTAssertEqual(item.speed.first().wait(), "↓ 1.5 MB/s ↑ 454 KB/s")
    }

    func test_speed_whenSeeding_shouldContainOnlyUploadRate() {
        subject.send(MockTorrent(standardState: .seeding, downloadRate: 1_540_527, uploadRate: 465_158))
        XCTAssertEqual(item.speed.first().wait(), "↑ 454 KB/s")
    }

    func test_speed_whenInactive_shouldBeEmpty() throws {
        let states: [TorrentState] = [.paused, .checking, .queued, .error]
        for state in states {
            subject.send(MockTorrent(standardState: state))
            XCTAssertTrue(try item.speed.first().wait().value().isEmpty)
        }
    }

    func test_progressString() {
        subject.send(MockTorrent(progress: 0.189_838, downloaded: 130_583_716, size: 687_865_856))
        XCTAssertEqual(item.progressString.first().wait(), "124.5 MB / 656.0 MB (19%)")
    }

    let ratioStates: [TorrentState] = [.seeding, .paused, .checking, .queued, .error]

    func test_ratio() {
        for state in ratioStates {
            subject.send(MockTorrent(standardState: state, downloaded: 10_000, uploaded: 4254))
            XCTAssertEqual(item.ratioOrETA.first().wait(), "Ratio: 0.4")
        }
    }

    func test_ratio_whenInfinite_shouldFormatProperly() {
        for state in ratioStates {
            subject.send(MockTorrent(standardState: state, uploaded: 1))
            XCTAssertTrue(subject.value.ratio.isInfinite)
            XCTAssertEqual(item.ratioOrETA.first().wait(), "Ratio: ∞")
        }
    }

    func test_ratio_whenNaN_shouldFormatProperly() {
        for state in ratioStates {
            subject.send(MockTorrent(standardState: state))
            XCTAssertTrue(subject.value.ratio.isNaN)
            XCTAssertEqual(item.ratioOrETA.first().wait(), "Ratio: ∞")
        }
    }

    func test_eta() {
        subject.send(MockTorrent(eta: 361))
        XCTAssertEqual(item.ratioOrETA.first().wait(), "6m 1s")
    }

    func test_eta_whenZero_shouldFormatProperly() {
        XCTAssertEqual(item.ratioOrETA.first().wait(), "∞")
    }
}
