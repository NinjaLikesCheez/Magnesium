import Combine
@testable import Magnesium
import XCTest

class TorrentDetailInfoItemTests: TestCase {
    override func setUp() {
        super.setUp()
    }

    func test_id_shouldEqualName() {
        let item1 = TorrentDetailInfoItem(name: "1", value: .init(""))
        var item2 = TorrentDetailInfoItem(name: "1", value: .init(""))
        XCTAssertEqual(item1.id, item2.id)
        item2.name = "2"
        XCTAssertNotEqual(item1.id, item2.id)
    }
}
