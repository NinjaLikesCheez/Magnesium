import Combine
@testable import Magnesium
import XCTest

class TorrentListItemTests: XCTestCase {
    private var subject: CurrentValueSubject<MockTorrent, Never>!
    private var item: TorrentListItem!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        Current = .mock
        subject = CurrentValueSubject(MockTorrent())
        item = TorrentListItem(torrent: subject)
        cancellables = Set()
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
        var name: String?
        item.name.sink { name = $0 }.store(in: &cancellables)
        XCTAssertEqual(name, "name")
    }

    func test_progress() {
        subject.send(MockTorrent(progress: 0.189_838))
        var progress: Float?
        item.progress.sink { progress = $0 }.store(in: &cancellables)
        XCTAssertEqual(progress, 0.189_838)
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
            var color: UIColor?
            item.progressColor.sink { color = $0 }.store(in: &cancellables)
            XCTAssertEqual(color, result, "\(state)")
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
            var string: String?
            item.state.sink { string = $0 }.store(in: &cancellables)
            XCTAssertEqual(string, result, "\(state)")
        }
    }

    func test_speed_whenDownloading_shouldContainDownloadAndUploadRate() {
        subject.send(MockTorrent(downloadRate: 1_540_527, uploadRate: 465_158))
        var speed: String?
        item.speed.sink { speed = $0 }.store(in: &cancellables)
        XCTAssertEqual(speed, "↓ 1.5 MB/s ↑ 454 KB/s")
    }

    func test_speed_whenSeeding_shouldContainOnlyUploadRate() {
        subject.send(MockTorrent(standardState: .seeding, downloadRate: 1_540_527, uploadRate: 465_158))
        var speed: String?
        item.speed.sink { speed = $0 }.store(in: &cancellables)
        XCTAssertEqual(speed, "↑ 454 KB/s")
    }

    func test_speed_whenInactive_shouldBeEmpty() {
        let states: [TorrentState] = [.paused, .checking, .queued, .error]
        for state in states {
            subject.send(MockTorrent(standardState: state))
            var speed: String?
            item.speed.sink { speed = $0 }.store(in: &cancellables)
            XCTAssertTrue(speed?.isEmpty ?? false, "\(state)")
        }
    }

    func test_progressString() {
        subject.send(MockTorrent(progress: 0.189_838, downloaded: 130_583_716, size: 687_865_856))
        var progress: String?
        item.progressString.sink { progress = $0 }.store(in: &cancellables)
        XCTAssertEqual(progress, "124.5 MB / 656.0 MB (19%)")
    }

    let ratioStates: [TorrentState] = [.seeding, .paused, .checking, .queued, .error]

    func test_ratio() {
        for state in ratioStates {
            subject.send(MockTorrent(standardState: state, downloaded: 10_000, uploaded: 4254))
            var ratio: String?
            item.ratioOrETA.first().sink { ratio = $0 }.store(in: &cancellables)
            XCTAssertEqual(ratio, "Ratio: 0.4")
        }
    }

    func test_ratio_whenInfinite_shouldFormatProperly() {
        for state in ratioStates {
            subject.send(MockTorrent(standardState: state, uploaded: 1))
            XCTAssertTrue(subject.value.ratio.isInfinite)
            var ratio: String?
            item.ratioOrETA.first().sink { ratio = $0 }.store(in: &cancellables)
            XCTAssertEqual(ratio, "Ratio: ∞")
        }
    }

    func test_ratio_whenNaN_shouldFormatProperly() {
        for state in ratioStates {
            subject.send(MockTorrent(standardState: state))
            XCTAssertTrue(subject.value.ratio.isNaN)
            var ratio: String?
            item.ratioOrETA.sink { ratio = $0 }.store(in: &cancellables)
            XCTAssertEqual(ratio, "Ratio: ∞")
        }
    }

    func test_eta() {
        subject.send(MockTorrent(eta: 361))
        var eta: String?
        item.ratioOrETA.sink { eta = $0 }.store(in: &cancellables)
        XCTAssertEqual(eta, "6m 1s")
    }

    func test_eta_whenZero_shouldFormatProperly() {
        var eta: String?
        item.ratioOrETA.sink { eta = $0 }.store(in: &cancellables)
        XCTAssertEqual(eta, "∞")
    }
}
