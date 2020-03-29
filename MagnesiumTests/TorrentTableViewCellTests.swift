@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentTableViewCellTests: XCTestCase {
    func test_longName() {
        let torrent = MockTorrent(name: .snapshotLong)
        let cell = TorrentTableViewCell.mock(torrent: torrent)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_states() {
        for state in TorrentState.allCases {
            let torrent = MockTorrent(name: "Name", standardState: state, progress: 1)
            let cell = TorrentTableViewCell.mock(torrent: torrent)
            assertSnapshot(matching: SizingView(cell), as: .image, named: String(describing: state))
        }
    }

    func test_contentCompression() {
        let torrent = MockTorrent(
            name: "Name",
            downloadRate: 100_000_000_000,
            uploadRate: 100_000_000_000,
            eta: 100_000_000_000,
            downloaded: 100_000_000_000,
            size: 100_000_000_000
        )
        let cell = TorrentTableViewCell.mock(torrent: torrent)
        let traits = UITraitCollection(preferredContentSizeCategory: .extraExtraExtraLarge)
        assertSnapshot(matching: SizingView(cell), as: .image(traits: traits))
    }
}

private extension TorrentTableViewCell {
    static func mock<T: StandardTorrent>(torrent: T) -> TorrentTableViewCell {
        let cell = TorrentTableViewCell()
        cell.backgroundColor = .systemBackground
        cell.configure(with: .init(torrent: .init(torrent)))
        return cell
    }
}
