import Combine
@testable import Magnesium
import XCTest

class TorrentDetailFileItemTests: TestCase {
    private var fileSubject: CurrentValueSubject<StandardTorrentFile, Never>!
    private var item: TorrentDetailFileItem!

    override func setUp() {
        super.setUp()
        fileSubject = CurrentValueSubject(.mock(
            index: 0,
            name: "file.rar",
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

    func test_name() {
        XCTAssertEqual(item.name.first().wait(), "file.rar")
    }

    func test_progress() {
        XCTAssertEqual(item.progress.first().wait(), "19%")
    }
}
