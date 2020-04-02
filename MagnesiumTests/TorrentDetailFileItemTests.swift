import Combine
@testable import Magnesium
import XCTest

class TorrentDetailFileItemTests: TestCase {
    private var file: CurrentValueSubject<StandardTorrentFile, Never>!
    private var item: TorrentDetailFileItem!

    override func setUp() {
        super.setUp()
        file = CurrentValueSubject(.mock(
            index: 0,
            name: "file.rar",
            progress: 0.189_838
        ))
        item = TorrentDetailFileItem(file: file)
    }

    func test_id_shouldBeEqualToIndex() {
        var file = self.file.value
        XCTAssertEqual(TorrentDetailFileItem(file: CurrentValueSubject(file)).id, item.id)
        file.index = 1
        XCTAssertNotEqual(TorrentDetailFileItem(file: CurrentValueSubject(file)).id, item.id)
    }

    func test_name() {
        XCTAssertEqual(item.name.first().wait(), "file.rar")
    }

    func test_progress() {
        XCTAssertEqual(item.progress.first().wait(), "19%")
    }
}
