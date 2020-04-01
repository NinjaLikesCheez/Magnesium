import Combine
@testable import Magnesium
import SnapshotTesting
import XCTest

class TransmissionTorrentDetailViewModelImplementationTests: TestCase {
    private var client: MockTransmissionClient!
    private var implementation: StandardTorrentDetailImplementation<
        TransmissionTorrent,
        Never,
        TransmissionTorrentFile
    >!

    override func setUp() {
        super.setUp()
        client = MockTransmissionClient()
        implementation = .transmission(session: .init(client: client))
    }

    func test_refresh_shouldCallRefresher() {
        _ = implementation.refresh().wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_pause_shouldStop() {
        _ = implementation.pause(.mock(hash: "B")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_resume_shouldStart() {
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

    func test_verify_shouldVerify() {
        _ = implementation.verify(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_updateTrackers_shouldReannounce() {
        _ = implementation.updateTrackers(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_moveDownloadFolder_shouldSetLocation() {
        _ = implementation.moveDownloadFolder("/new", .mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }
}
