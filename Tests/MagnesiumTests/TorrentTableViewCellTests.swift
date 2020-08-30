@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentTableViewCellTests: TestCase {
    func test_snapshot_withLongName() {
        let cell = TorrentTableViewCell.mock(torrent: .mock(name: .snapshotLong))
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_snapshot_states() {
        for state in TorrentState.allCases {
            let cell = TorrentTableViewCell.mock(torrent: .mock(name: "Name", progress: 1, state: state))
            assertSnapshot(matching: SizingView(cell), as: .image, named: String(describing: state))
        }
    }

    func test_snapshot_contentCompression() {
        let cell = TorrentTableViewCell.mock(torrent: .mock(
            downloaded: 100_000_000_000,
            downloadRate: 100_000_000_000,
            eta: 100_000_000_000,
            name: "Name",
            size: 100_000_000_000,
            uploadRate: 100_000_000_000
        ))
        let traits = UITraitCollection(preferredContentSizeCategory: .extraExtraExtraLarge)
        assertSnapshot(matching: SizingView(cell), as: .image(traits: traits))
    }

    func test_snapshot_withLabel() {
        let cell = TorrentTableViewCell.mock(torrent: .mock(label: "label", name: "Name"))
        assertSnapshot(matching: SizingView(cell), as: .image)
    }
}

private extension TorrentTableViewCell {
    static func mock(torrent: StandardTorrent) -> TorrentTableViewCell {
        let cell = TorrentTableViewCell()
        cell.backgroundColor = .systemBackground
        cell.configure(with: .init(torrentSubject: .init(torrent)))
        return cell
    }
}
