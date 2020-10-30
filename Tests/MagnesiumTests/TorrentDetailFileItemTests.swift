import Combine
@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentDetailFileItemTests: TestCase {
    private var fileSubject: CurrentValueSubject<StandardTorrentFile, Never>!
    private var item: TorrentDetailFileItem!

    override func setUp() {
        super.setUp()
        fileSubject = CurrentValueSubject(.mock(
            index: 0,
            name: "file.rar",
            size: 100_000_000,
            progress: 0.189_838
        ))
        item = TorrentDetailFileItem(fileSubject: fileSubject)
    }

    func test_id_shouldBeEqualToIndex() {
        var file = fileSubject.value
        XCTAssertEqual(TorrentDetailFileItem(fileSubject: CurrentValueSubject(file)).id, item.id)
        file.index = 1
        XCTAssertNotEqual(TorrentDetailFileItem(fileSubject: CurrentValueSubject(file)).id, item.id)
    }

    func test_name() throws {
        XCTAssertEqual(try item.name.first().wait().singleValue(), "file.rar")
    }

    func test_info() throws {
        XCTAssertEqual(
            try item.info.first().wait().singleValue(),
            L10n.File.progress(
                size: Formatters.bytes.string(fromByteCount: fileSubject.value.size),
                progress: Formatters.percentage.string(for: fileSubject.value.progress) ?? ""
            )
        )
    }
}
