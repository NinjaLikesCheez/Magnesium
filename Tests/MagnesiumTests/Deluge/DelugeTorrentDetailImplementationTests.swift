import Combine
import Deluge
@testable import Magnesium
import SnapshotTesting
import XCTest

class DelugeTorrentDetailImplementationTests: TestCase {
    private var client: MockDelugeClient!
    private var implementation: StandardTorrentDetailImplementation!

    override func setUp() {
        super.setUp()
        client = MockDelugeClient()
        implementation = .deluge(session: .init(client: client))
    }

    func test_refresh_shouldPerformUpdateUIRequest() {
        _ = implementation.refresh().wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_refreshFiles_shouldRefreshFiles() throws {
        let items: [DelugeTorrentItem] = [
            .directory(name: "d0", items: [.file(.mock(index: 0, name: "f0"))]),
            .file(.mock(index: 1, name: "f1")),
        ]
        client.results.append((
            method: "web.get_torrent_files",
            result: Just(items as Any).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))
        let files = try implementation.refreshFiles(.mock()).wait().singleValue()
        XCTAssertEqual(files, [.mock(index: 0, name: "f0"), .mock(index: 1, name: "f1")])
    }

    func test_pause_shouldPerformPauseRequest() {
        _ = implementation.pause(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_resume_shouldPerformResumeRequest() {
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

    func test_verify_shouldPerformRecheckRequest() {
        _ = implementation.verify(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_setLabel_shouldPerformSetLabelsRequest() {
        _ = implementation.setLabel(.mock(name: "label"), .mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_updateTrackers_shouldPerformReannounceRequest() {
        _ = implementation.updateTrackers(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_moveDownloadFolder_shouldPerformMoveStorageRequest() {
        _ = implementation.moveDownloadFolder("/new", .mock(hash: "A"))
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_setPriority_shouldPerformSetOptionsRequest() {
        _ = implementation.setPriority(
            .mock(hash: "A"),
            [.mock(index: 0), .mock(index: 1), .mock(index: 2), .mock(index: 3), .mock(index: 4)],
            [
                .mock(index: 0): .disabled,
                .mock(index: 1): .low,
                .mock(index: 2): .normal,
                .mock(index: 3): .high,
            ]
        )
        assertSnapshot(matching: client.requests, as: .requests)
    }
}
