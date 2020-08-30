@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentDetailFileTableViewCellTests: TestCase {
    func test_snapshot() {
        let cell = TorrentDetailFileTableViewCell.mock(file: .mock(), isLastRow: false)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_snapshot_whenLastRow() {
        let cell = TorrentDetailFileTableViewCell.mock(file: .mock(), isLastRow: true)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_snapshot_withLongName() {
        let cell = TorrentDetailFileTableViewCell.mock(file: .mock(name: .snapshotLong), isLastRow: false)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_snapshot_priorities() {
        for priority in TorrentPriority.allCases {
            let cell = TorrentDetailFileTableViewCell.mock(file: .mock(priority: priority), isLastRow: false)
            assertSnapshot(matching: SizingView(cell), as: .image, named: String(describing: priority))
        }
    }
}

private extension TorrentDetailFileTableViewCell {
    static func mock(file: StandardTorrentFile, isLastRow: Bool) -> TorrentDetailFileTableViewCell {
        let cell = TorrentDetailFileTableViewCell()
        cell.backgroundColor = .systemBackground
        cell.configure(with: .init(fileSubject: .init(file)), isLastRow: isLastRow)
        return cell
    }
}
