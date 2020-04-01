import Combine
@testable import Magnesium
import SnapshotTesting
import XCTest

class TransmissionTorrentDetailViewModelImplementationTests: TestCase {
    private var client: MockTransmissionClient!
    private var implementation: TransmissionTorrentDetailViewModelImplementation!

    override func setUp() {
        super.setUp()
        client = MockTransmissionClient()
        implementation = TransmissionTorrentDetailViewModelImplementation(session: .init(client: client))
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
        _ = implementation.remove(.mock(hash: "A"), removeData: false).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_remove_withRemoveData_shouldRemove() {
        _ = implementation.remove(.mock(hash: "A"), removeData: true).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_verify_shouldVerify() {
        _ = implementation.verify(.mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_updateTrackers_shouldReannounce() {
        _ = implementation.updateTrackers(for: .mock(hash: "A")).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_moveDownloadFolder_shouldSetLocation() {
        _ = implementation.moveDownloadFolder(for: .mock(hash: "A"), to: "/new").wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }
}
