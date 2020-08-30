@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentDetailHeaderTableViewCellTests: TestCase {
    func test_snapshot() {
        let cell = TorrentDetailHeaderTableViewCell.mock(torrent: .mock(name: "Name"))
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_snapshot_withLongName() {
        let cell = TorrentDetailHeaderTableViewCell.mock(torrent: .mock(name: .snapshotLong))
        assertSnapshot(matching: SizingView(cell), as: .image)
    }
}

private extension TorrentDetailHeaderTableViewCell {
    static func mock(torrent: StandardTorrent) -> TorrentDetailHeaderTableViewCell {
        let cell = TorrentDetailHeaderTableViewCell()
        cell.backgroundColor = .systemBackground
        cell.configure(with: .init(torrentSubject: .init(torrent)))
        return cell
    }
}
