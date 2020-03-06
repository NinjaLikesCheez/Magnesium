@testable import Magnesium
import XCTest

class TransmissionTorrentFileTests: XCTestCase {
    func test_progress_shouldEqualDownloadedOverSize() {
        let file = TransmissionTorrentFile.mock(size: 100_000_000, downloaded: 10_000_000)
        XCTAssertEqual(file.progress, 0.1)
    }
}
