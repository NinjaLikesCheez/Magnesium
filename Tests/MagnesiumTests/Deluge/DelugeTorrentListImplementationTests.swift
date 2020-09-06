import Combine
import Deluge
@testable import Magnesium
import Preferences
import SnapshotTesting
import XCTest

class DelugeTorrentListImplementationTests: TestCase {
    private var client: MockDelugeClient!
    private var implementation: StandardTorrentListImplementation!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        client = MockDelugeClient()
        implementation = .deluge(.init(client: client))
    }

    func test_refresh_shouldPerformUpdateUIRequest() {
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
        XCTAssertEqual(error.title, L10n.Error.invalidURL)
        XCTAssertEqual(error.message, L10n.Error.invalidURLMessage)
    }

    func test_addLink_withMagnetLink_shouldPerformAddMagnetRequest() {
        _ = implementation.addLink("magnet:?").wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_addLink_withMagnetLink_whenFails_shouldReturnError() throws {
        client.results.append((
            method: "core.add_torrent_magnet",
            result: Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        let error = try implementation.addLink("magnet:?").wait().error()
        XCTAssertEqual(error.title, L10n.Error.failedToAddTorrent)
    }

    func test_addLink_withRegularLink_shouldPerformAddURLRequest() {
        _ = implementation.addLink("http://example.com").wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_addLink_withRegularLink_whenFails_shouldReturnError() throws {
        client.results.append((
            method: "core.add_torrent_url",
            result: Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        let error = try implementation.addLink("http://example.com").wait().error()
        XCTAssertEqual(error.title, L10n.Error.failedToAddTorrent)
    }

    func test_pause_shouldPerformPauseRequest() {
        _ = implementation.pause([.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_resume_shouldPerformResumeRequest() {
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

    func test_verify_shouldPerformRecheckRequest() {
        _ = implementation.verify([.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_setLabel_shouldPerformSetLabelsRequest() {
        _ = implementation.setLabel(.mock(name: "label1"), [.mock(hash: "A"), .mock(hash: "B")])
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_updateTrackers_shouldPerformReannounceRequest() {
        _ = implementation.updateTrackers([.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_moveDownloadFolder_shouldPerformMoveStorageRequest() {
        _ = implementation.moveDownloadFolder("/new", [.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }
}
