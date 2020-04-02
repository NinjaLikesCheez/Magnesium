@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentDetailHeaderTableViewCellTests: TestCase {
    func test_view() {
        let cell = TorrentDetailHeaderTableViewCell.mock(torrent: .mock(name: "Name"))
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_longName() {
        let cell = TorrentDetailHeaderTableViewCell.mock(torrent: .mock(name: .snapshotLong))
        assertSnapshot(matching: SizingView(cell), as: .image)
    }
}

private extension TorrentDetailHeaderTableViewCell {
    static func mock(torrent: StandardTorrent) -> TorrentDetailHeaderTableViewCell {
        let cell = TorrentDetailHeaderTableViewCell()
        cell.backgroundColor = .systemBackground
        cell.configure(with: .init(torrent: .init(torrent)))
        return cell
    }
}
