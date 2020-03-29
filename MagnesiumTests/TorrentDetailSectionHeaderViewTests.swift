@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentDetailSectionHeaderViewTests: XCTestCase {
    func test_view() {
        let cell = TorrentDetailSectionHeaderView.mock(title: "Title")
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_longName() {
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
