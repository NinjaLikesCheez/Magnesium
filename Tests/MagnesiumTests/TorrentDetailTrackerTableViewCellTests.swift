@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentDetailTrackerTableViewCellTests: TestCase {
    func test_snapshot() {
        let cell = TorrentDetailTrackerTableViewCell.mock(
            tracker: "http://tracker.example.com:9000/announce",
            isLastRow: false
        )
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_snapshot_whenLastRow() {
        let cell = TorrentDetailTrackerTableViewCell.mock(
            tracker: "http://tracker.example.com:9000/announce",
            isLastRow: true
        )
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_snapshot_withLongTrackerURL() {
        let cell = TorrentDetailTrackerTableViewCell.mock(tracker: .snapshotLong, isLastRow: false)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }
}

private extension TorrentDetailTrackerTableViewCell {
    static func mock(tracker: String, isLastRow: Bool) -> TorrentDetailTrackerTableViewCell {
        let cell = TorrentDetailTrackerTableViewCell()
        cell.backgroundColor = .systemBackground
        cell.configure(tracker: tracker, isLastRow: isLastRow)
        return cell
    }
}
