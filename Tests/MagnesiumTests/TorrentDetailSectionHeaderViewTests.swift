@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentDetailSectionHeaderViewTests: TestCase {
    func test_snapshot() {
        let cell = TorrentDetailSectionHeaderView.mock(title: "Title")
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_snapshot_withLongName() {
        let cell = TorrentDetailSectionHeaderView.mock(title: .snapshotLong)
        assertSnapshot(matching: SizingView(cell), as: .image)
    }
}

private extension TorrentDetailSectionHeaderView {
    static func mock(title: String) -> TorrentDetailSectionHeaderView {
        let cell = TorrentDetailSectionHeaderView()
        cell.backgroundColor = .systemBackground
        cell.configure(title: title)
        return cell
    }
}
