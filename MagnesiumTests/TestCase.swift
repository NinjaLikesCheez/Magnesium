@testable import Magnesium
import SnapshotTesting
import XCTest

// swiftlint:disable:next testcase_inheritance
class TestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        diffTool = "ksdiff"
//        record = true
        Current = .mock
    }
}
