@testable import Magnesium
import SnapshotTesting
import XCTest

// swiftlint:disable:next testcase_inheritance
class TestCase: XCTestCase {
    override func setUp() {
        super.setUp()
//        isRecording = true
        diffTool = "ksdiff"
        Current = .mock
    }
}
