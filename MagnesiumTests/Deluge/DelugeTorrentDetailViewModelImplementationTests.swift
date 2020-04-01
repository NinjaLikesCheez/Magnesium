import Combine
import Deluge
@testable import Magnesium
import SnapshotTesting
import XCTest

class DelugeTorrentDetailViewModelImplementationTests: TestCase {
    private var client: MockDelugeClient!
    private var implementation: StandardTorrentDetailImplementation<DelugeTorrent, DelugeLabel, DelugeTorrentFile>!

    override func setUp() {
        super.setUp()
        client = MockDelugeClient()
        implementation = .deluge(session: .init(client: client))
    }

    func test_refresh_shouldCallRefresher() {
        _ = implementation.refresh().wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_pause_shouldPause() {
        _ = implementation.pause(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_resume_shouldResume() {
        _ = implementation.resume(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_remove_withKeepData_shouldRemove() {
        _ = implementation.remove(.mock(hash: "A"), false).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_remove_withRemoveData_shouldRemove() {
        _ = implementation.remove(.mock(hash: "A"), true).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_verify_shouldRecheck() {
        _ = implementation.verify(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_setLabel_shouldSetLabels() {
        _ = implementation.setLabel(.mock(name: "label"), .mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_updateTrackers_shouldReannounce() {
        _ = implementation.updateTrackers(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_moveDownloadFolder_shouldMoveStorage() {
        _ = implementation.moveDownloadFolder("/new", .mock(hash: "A"))
        assertSnapshot(matching: client.requests, as: .requests)
    }
}
