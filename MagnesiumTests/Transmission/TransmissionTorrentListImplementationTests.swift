import Combine
@testable import Magnesium
import Preferences
import SnapshotTesting
import Transmission
import XCTest

class TransmissionTorrentListImplementationTests: TestCase {
    private var client: MockTransmissionClient!
    private var implementation: StandardTorrentListImplementation!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        client = MockTransmissionClient()
        implementation = .transmission(.init(client: client))
    }

    func test_refresh_shouldGetTorrents() {
        _ = implementation.refresh().wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_detailViewModel_shouldReturnExpectedViewModelType() {
        let viewModel = implementation.detailViewModel(
            CurrentValueSubject(.mock()),
            CurrentValueSubject([])
        ).base as AnyObject
        XCTAssertType(viewModel, StandardTorrentDetailViewModel.self)
    }

    func test_addLink_withInvalidURL_shouldReturnError() throws {
        assertSnapshot(matching: try implementation.addLink("^").wait().error(), as: .dump)
    }

    func test_addLink_withMagnetLink_shouldAddURL() {
        _ = implementation.addLink("magnet:?").wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_addLink_withRegularLink_shouldAddMagnetURL() {
        _ = implementation.addLink("http://example.com").wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_addLink_whenFails_shouldReturnError() throws {
        client.results.append((
            "torrent-add",
            Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        assertSnapshot(matching: try implementation.addLink("http://example.com").wait().error(), as: .dump)
    }

    func test_pause_shouldStop() {
        _ = implementation.pause([.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_resume_shouldStart() {
        _ = implementation.resume([.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_remove_withKeepData_shouldRemove() {
        _ = implementation.remove([.mock(hash: "A"), .mock(hash: "B")], false).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_remove_withRemoveData_shouldRemove() {
        _ = implementation.remove([.mock(hash: "A"), .mock(hash: "B")], true).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_verify_shouldVerify() {
        _ = implementation.verify([.mock(hash: "A"), .mock(hash: "B")])
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_updateTrackers_shouldReannounce() {
        _ = implementation.updateTrackers([.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_moveDownloadFolder_shouldSetLocation() {
        _ = implementation.moveDownloadFolder("/new", [.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }
}
