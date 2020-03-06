import Combine
@testable import Magnesium
import XCTest

class TorrentDetailFileItemTests: XCTestCase {
    private var file: CurrentValueSubject<MockTorrentFile, Never>!
    private var item: TorrentDetailFileItem!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
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

    func test_name() {
        var name: String?
        item.name.sink { name = $0 }.store(in: &observers)
        XCTAssertEqual(name, "file.rar")
    }

    func test_progress() {
        var progress: String?
        item.progress.sink { progress = $0 }.store(in: &observers)
        XCTAssertEqual(progress, "19%")
    }
}
