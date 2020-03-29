import Combine
@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentDetailInfoTableViewCellTests: XCTestCase {
    func test_view() {
        let cell = TorrentDetailInfoTableViewCell.mock(
            name: "Name",
            value: "Value",
            expandedValue: "ExpandedValue",
            isExpanded: false,
            isLastRow: false
        )
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_view_whenLastRow() {
        let cell = TorrentDetailInfoTableViewCell.mock(
            name: "Name",
            value: "Value",
            expandedValue: "ExpandedValue",
            isExpanded: false,
            isLastRow: true
        )
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_view_whenExpanded() {
        let cell = TorrentDetailInfoTableViewCell.mock(
            name: "Name",
            value: "Value",
            expandedValue: "ExpandedValue",
            isExpanded: true,
            isLastRow: false
        )
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_longValues() {
        let cell = TorrentDetailInfoTableViewCell.mock(
            name: "Name", // name should never be long
            value: .snapshotLong,
            expandedValue: .snapshotLong,
            isExpanded: false,
            isLastRow: false
        )
        assertSnapshot(matching: SizingView(cell), as: .image)
    }

    func test_longValues_whenExpanded() {
        let cell = TorrentDetailInfoTableViewCell.mock(
            name: "Name", // name should never be long
            value: .snapshotLong,
            expandedValue: .snapshotLong,
            isExpanded: true,
            isLastRow: false
        )
        assertSnapshot(matching: SizingView(cell), as: .image)
    }
}

private extension TorrentDetailInfoTableViewCell {
    static func mock(
        name: String,
        value: String,
        expandedValue: String,
        isExpanded: Bool,
        isLastRow: Bool
    ) -> TorrentDetailInfoTableViewCell {
        let cell = TorrentDetailInfoTableViewCell()
        cell.backgroundColor = .systemBackground
        cell.configure(
            with: .init(
                name: name,
                value: Just(value).eraseToAnyPublisher(),
                expandedValue: Just(expandedValue).eraseToAnyPublisher()
            ),
            isExpanded: isExpanded,
            isLastRow: isLastRow
        )
        return cell
    }
}
