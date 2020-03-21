import Combine
@testable import Magnesium
import XCTest

class TorrentDetailInfoItemTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Current = .mock
    }

    func test_id_shouldEqualName() {
        let item1 = TorrentDetailInfoItem(name: "1", value: Just("").eraseToAnyPublisher())
        var item2 = TorrentDetailInfoItem(name: "1", value: Just("").eraseToAnyPublisher())
        XCTAssertEqual(item1.id, item2.id)
        item2.name = "2"
        XCTAssertNotEqual(item1.id, item2.id)
    }
}
