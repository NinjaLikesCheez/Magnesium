@testable import Magnesium
import XCTest

class TransmissionTorrentFileTests: TestCase {
    override func setUp() {
        super.setUp()
    }

    func test_progress_shouldEqualDownloadedOverSize() {
        let file = TransmissionTorrentFile.mock(size: 100_000_000, downloaded: 10_000_000)
        XCTAssertEqual(file.standard.progress, 0.1)
    }
}
