@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentDetailHeaderTableViewCellTests: TestCase {
    func test_view() {
        let torrent = MockTorrent(name: "Name")
        let cell = TorrentDetailHeaderTableViewCell.mock(torrent: torrent)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_longName() {
        let torrent = MockTorrent(name: .snapshotLong)
        let cell = TorrentDetailHeaderTableViewCell.mock(torrent: torrent)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }
}

private extension TorrentDetailHeaderTableViewCell {
    static func mock<T: StandardTorrent>(torrent: T) -> TorrentDetailHeaderTableViewCell {
        let cell = TorrentDetailHeaderTableViewCell()
        cell.backgroundColor = .systemBackground
        cell.configure(with: .init(torrent: .init(torrent)))
        return cell
    }
}
