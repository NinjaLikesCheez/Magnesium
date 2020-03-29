@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentDetailFileTableViewCellTests: TestCase {
    func test_view() {
        let file = MockTorrentFile(name: "Name")
        let cell = TorrentDetailFileTableViewCell.mock(file: file, isLastRow: false)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_view_whenLastRow() {
        let file = MockTorrentFile(name: "Name")
        let cell = TorrentDetailFileTableViewCell.mock(file: file, isLastRow: true)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_longName() {
        let file = MockTorrentFile(name: .snapshotLong)
        let cell = TorrentDetailFileTableViewCell.mock(file: file, isLastRow: false)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }
}

private extension TorrentDetailFileTableViewCell {
    static func mock<T: StandardTorrentFile>(file: T, isLastRow: Bool) -> TorrentDetailFileTableViewCell {
        let cell = TorrentDetailFileTableViewCell()
        cell.backgroundColor = .systemBackground
        cell.configure(with: .init(file: .init(file)), isLastRow: isLastRow)
        return cell
    }
}
