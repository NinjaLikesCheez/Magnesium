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

    func test_refresh_shouldPerformTorrentsRequest() {
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
        let error = try implementation.addLink("^").wait().error()
        XCTAssertEqual(error.title, "Invalid URL")
        XCTAssertEqual(error.message, "That URL doesn't appear to be valid.")
    }

    func test_addLink_withMagnetLink_shouldPerformAddRequest() {
        _ = implementation.addLink("magnet:?").wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_addLink_withRegularLink_shouldPerformAddRequest() {
        _ = implementation.addLink("http://example.com").wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_addLink_whenFails_shouldReturnExpectedError() throws {
        client.results.append((
            "torrent-add",
            Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        assertSnapshot(matching: try implementation.addLink("http://example.com").wait().error(), as: .dump)
    }

    func test_pause_shouldPerformStopRequest() {
        _ = implementation.pause([.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_resume_shouldPerformStartRequest() {
        _ = implementation.resume([.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_remove_withKeepData_shouldPerformRemoveRequest() {
        _ = implementation.remove([.mock(hash: "A"), .mock(hash: "B")], false).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_remove_withRemoveData_shouldPerformRemoveRequest() {
        _ = implementation.remove([.mock(hash: "A"), .mock(hash: "B")], true).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_verify_shouldPerformVerifyRequest() {
        _ = implementation.verify([.mock(hash: "A"), .mock(hash: "B")])
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_updateTrackers_shouldPerformReannounceRequest() {
        _ = implementation.updateTrackers([.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_moveDownloadFolder_shouldPerformSetLocationRequest() {
        _ = implementation.moveDownloadFolder("/new", [.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }
}
