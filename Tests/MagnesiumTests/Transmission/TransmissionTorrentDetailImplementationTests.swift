import Combine
@testable import Magnesium
import SnapshotTesting
import Transmission
import XCTest

class TransmissionTorrentDetailImplementationTests: TestCase {
    private var client: MockTransmissionClient!
    private var implementation: StandardTorrentDetailImplementation!

    override func setUp() {
        super.setUp()
        client = MockTransmissionClient()
        implementation = .transmission(session: .init(client: client))
    }

    func test_refresh_shouldPerformTorrentsRequest() {
        _ = implementation.refresh().wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_refreshFiles_shouldPerformTorrentFilesRequest() throws {
        let files: [TransmissionTorrentFile] = [
            .mock(index: 0, name: "f0", size: 1),
            .mock(index: 0, name: "f1", size: 1),
        ]
        client.results.append((
            method: "torrent-get",
            result: Just(files as Any).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
        ))
        let results = try implementation.refreshFiles(.mock()).wait().singleValue()
        XCTAssertEqual(results, files.map(\.standard))
    }

    func test_pause_shouldPerformStopRequest() {
        _ = implementation.pause(.mock(hash: "B")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_resume_shouldPerformStartRequest() {
        _ = implementation.resume(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_remove_withKeepData_shouldPerformRemoveRequest() {
        _ = implementation.remove(.mock(hash: "A"), false).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_remove_withRemoveData_shouldPerformRemoveRequest() {
        _ = implementation.remove(.mock(hash: "A"), true).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_verify_shouldPerformVerifyRequest() {
        _ = implementation.verify(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_updateTrackers_shouldPerformReannounceRequest() {
        _ = implementation.updateTrackers(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_moveDownloadFolder_shouldPerformSetLocationRequest() {
        _ = implementation.moveDownloadFolder("/new", .mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_setPriority_shouldPerformSetOptionsRequest() {
        _ = implementation.setPriority(
            .mock(hash: "A"),
            [],
            [
                .mock(index: 0): .disabled,
                .mock(index: 1, priority: .disabled): .low,
                .mock(index: 2): .normal,
                .mock(index: 3): .high,
            ]
        )
        assertSnapshot(matching: client.requests, as: .requests)
    }
}
