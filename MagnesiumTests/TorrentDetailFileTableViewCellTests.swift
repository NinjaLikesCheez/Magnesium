@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentDetailFileTableViewCellTests: TestCase {
    func test_view() {
        let cell = TorrentDetailFileTableViewCell.mock(file: .mock(name: "Name"), isLastRow: false)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_view_whenLastRow() {
        let cell = TorrentDetailFileTableViewCell.mock(file: .mock(name: "Name"), isLastRow: true)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_longName() {
        let cell = TorrentDetailFileTableViewCell.mock(file: .mock(name: .snapshotLong), isLastRow: false)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }
}

private extension TorrentDetailFileTableViewCell {
    static func mock(file: StandardTorrentFile, isLastRow: Bool) -> TorrentDetailFileTableViewCell {
        let cell = TorrentDetailFileTableViewCell()
        cell.backgroundColor = .systemBackground
        cell.configure(with: .init(file: .init(file)), isLastRow: isLastRow)
        return cell
    }
}
