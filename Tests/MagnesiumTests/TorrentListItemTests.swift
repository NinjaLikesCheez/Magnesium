import Combine
@testable import Magnesium
import XCTest

class TorrentListItemTests: TestCase {
    private var subject: CurrentValueSubject<StandardTorrent, Never>!
    private var item: TorrentListItem!

    override func setUp() {
        super.setUp()
        subject = CurrentValueSubject(.mock())
        item = TorrentListItem(torrentSubject: subject)
    }

    func test_identity_shouldBeEqualToHash() {
        let torrent1 = StandardTorrent.mock(hash: "A")
        var torrent2 = StandardTorrent.mock(hash: "A")
        XCTAssertEqual(
            TorrentListItem(torrentSubject: CurrentValueSubject(torrent1)).id,
            TorrentListItem(torrentSubject: CurrentValueSubject(torrent2)).id
        )

        torrent2.hash = "B"
        XCTAssertNotEqual(
            TorrentListItem(torrentSubject: CurrentValueSubject(torrent1)).id,
            TorrentListItem(torrentSubject: CurrentValueSubject(torrent2)).id
        )
    }

    func test_equality_shouldBeDerivedFromID() {
        let torrent1 = StandardTorrent.mock(hash: "A")
        var torrent2 = StandardTorrent.mock(hash: "A")
        XCTAssertEqual(
            TorrentListItem(torrentSubject: CurrentValueSubject(torrent1)),
            TorrentListItem(torrentSubject: CurrentValueSubject(torrent2))
        )

        torrent2.hash = "B"
        XCTAssertNotEqual(
            TorrentListItem(torrentSubject: CurrentValueSubject(torrent1)),
            TorrentListItem(torrentSubject: CurrentValueSubject(torrent2))
        )
    }

    func test_hashValue_shouldBeDerivedFromID() {
        let torrent1 = StandardTorrent.mock(hash: "A")
        var torrent2 = StandardTorrent.mock(hash: "A")
        XCTAssertEqual(
            TorrentListItem(torrentSubject: CurrentValueSubject(torrent1)).hashValue,
            TorrentListItem(torrentSubject: CurrentValueSubject(torrent2)).hashValue
        )

        torrent2.hash = "B"
        XCTAssertNotEqual(
            TorrentListItem(torrentSubject: CurrentValueSubject(torrent1)).hashValue,
            TorrentListItem(torrentSubject: CurrentValueSubject(torrent2)).hashValue
        )
    }

    func test_name() throws {
        subject.send(.mock(name: "name"))
        XCTAssertEqual(try item.name.first().wait().singleValue(), "name")
    }

    func test_progress() throws {
        subject.send(.mock(progress: 0.189))
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
            subject.send(.mock(state: state))
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
            subject.send(.mock(state: state))
            XCTAssertEqual(try item.status.first().wait().singleValue(), result, String(describing: state))
        }
    }

    func test_speed_whenDownloading_shouldContainDownloadAndUploadRate() throws {
        subject.send(StandardTorrent.mock(downloadRate: 1_540_527, uploadRate: 465_158))
        XCTAssertEqual(
            try item.speed.first().wait().singleValue(),
            L10n.Torrent.downloadUploadSpeed(
                downloadSpeed: Formatters.bytes.string(fromByteCount: 1_540_527),
                uploadSpeed: Formatters.bytes.string(fromByteCount: 465_158)
            )
        )
    }

    func test_speed_whenSeeding_shouldContainOnlyUploadRate() throws {
        subject.send(StandardTorrent.mock(downloadRate: 1_540_527, state: .seeding, uploadRate: 465_158))
        XCTAssertEqual(
            try item.speed.first().wait().singleValue(),
            L10n.Torrent.uploadSpeed(Formatters.bytes.string(fromByteCount: 465_158))
        )
    }

    func test_speed_whenInactive_shouldBeEmpty() throws {
        let states: [TorrentState] = [.paused, .checking, .queued, .error]
        for state in states {
            subject.send(.mock(state: state))
            XCTAssertTrue(try item.speed.first().wait().singleValue().isEmpty)
        }
    }

    func test_progressText() throws {
        subject.send(.mock(downloaded: 130_583_716, progress: 0.189, size: 687_865_856))
        XCTAssertEqual(
            try item.progressText.first().wait().singleValue(),
            L10n.Torrent.progress(
                downloaded: Formatters.bytes.string(fromByteCount: 130_583_716),
                size: Formatters.bytes.string(fromByteCount: 687_865_856),
                progress: Formatters.percentage.string(from: 0.189) ?? ""
            )
        )
    }

    let ratioStates: [TorrentState] = [.seeding, .paused, .checking, .queued, .error]

    func test_ratio() {
        for state in ratioStates {
            subject.send(.mock(downloaded: 10_000, state: state, uploaded: 4254))
            XCTAssertEqual(
                try item.ratioOrETA.first().wait().singleValue(),
                L10n.Torrent.ratio(Formatters.number(precision: 1).string(for: 4254 / 10_000.0) ?? "")
            )
        }
    }

    func test_ratio_whenInfinite_shouldFormatProperly() throws {
        for state in ratioStates {
            subject.send(.mock(state: state, uploaded: 1))
            XCTAssertTrue(subject.value.ratio.isInfinite)
            XCTAssertEqual(try item.ratioOrETA.first().wait().singleValue(), L10n.Torrent.ratio(L10n.Common.infinity))
        }
    }

    func test_ratio_whenNaN_shouldFormatProperly() throws {
        for state in ratioStates {
            subject.send(.mock(state: state))
            XCTAssertTrue(subject.value.ratio.isNaN)
            XCTAssertEqual(try item.ratioOrETA.first().wait().singleValue(), L10n.Torrent.ratio(L10n.Common.infinity))
        }
    }

    func test_eta() throws {
        subject.send(StandardTorrent.mock(eta: 361))
        XCTAssertEqual(try item.ratioOrETA.first().wait().singleValue(), Formatters.eta.string(from: 361) ?? "")
    }

    func test_eta_whenZero_shouldFormatProperly() throws {
        XCTAssertEqual(try item.ratioOrETA.first().wait().singleValue(), L10n.Common.infinity)
    }
}
