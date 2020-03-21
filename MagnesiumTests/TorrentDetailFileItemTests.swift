import Combine
@testable import Magnesium
import XCTest

class TorrentDetailFileItemTests: XCTestCase {
    private var file: CurrentValueSubject<MockTorrentFile, Never>!
    private var item: TorrentDetailFileItem!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        Current = .mock
        file = CurrentValueSubject(MockTorrentFile(
            index: 0,
            name: "file.rar",
            progress: 0.189_838
        ))
        item = TorrentDetailFileItem(file: file)
        cancellables = Set()
    }

    func test_id_shouldBeEqualToIndex() {
        var file = self.file.value
        XCTAssertEqual(TorrentDetailFileItem(file: CurrentValueSubject(file)).id, item.id)
        file.index = 1
        XCTAssertNotEqual(TorrentDetailFileItem(file: CurrentValueSubject(file)).id, item.id)
    }

    func test_name() {
        var name: String?
        item.name.sink { name = $0 }.store(in: &cancellables)
        XCTAssertEqual(name, "file.rar")
    }

    func test_progress() {
        var progress: String?
        item.progress.sink { progress = $0 }.store(in: &cancellables)
        XCTAssertEqual(progress, "19%")
    }
}
