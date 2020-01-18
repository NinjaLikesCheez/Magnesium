@testable import Deluge
import XCTest

final class DelugeTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Deluge().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
