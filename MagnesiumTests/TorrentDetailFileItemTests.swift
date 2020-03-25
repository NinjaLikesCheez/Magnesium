import Combine
@testable import Magnesium
import XCTest

class TorrentDetailFileItemTests: XCTestCase {
    private var file: CurrentValueSubject<MockTorrentFile, Never>!
    private var item: TorrentDetailFileItem!

    override func setUp() {
        super.setUp()
        Current = .mock
        file = CurrentValueSubject(MockTorrentFile(
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

    func test_name() throws {
        XCTAssertEqual(try item.name.first().wait().value(), "file.rar")
    }

    func test_progress() {
        XCTAssertEqual(try item.progress.first().wait().value(), "19%")
    }
}
