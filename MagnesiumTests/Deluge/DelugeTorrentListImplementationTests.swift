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

    func test_refresh_shouldGetCurrentState() {
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

    func test_addLink_withMagnetLink_shouldAddMagnetURL() {
        _ = implementation.addLink("magnet:?").wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_addLink_withMagnetLink_whenFails_shouldReturnError() throws {
        client.results.append((
            method: "core.add_torrent_magnet",
            result: Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        assertSnapshot(matching: try implementation.addLink("magnet:?").wait().error(), as: .dump)
    }

    func test_addLink_withRegularLink_shouldAddMagnetURL() {
        _ = implementation.addLink("http://example.com").wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_addLink_withRegularLink_whenFails_shouldReturnError() throws {
        client.results.append((
            method: "core.add_torrent_url",
            result: Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        assertSnapshot(matching: try implementation.addLink("http://example.com").wait().error(), as: .dump)
    }

    func test_pause_shouldPause() {
        _ = implementation.pause([.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_resume_shouldResume() {
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

    func test_verify_shouldRecheck() {
        _ = implementation.verify([.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_setLabel_shouldSetLabels() {
        _ = implementation.setLabel(.mock(name: "label1"), [.mock(hash: "A"), .mock(hash: "B")])
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_updateTrackers_shouldReannounce() {
        _ = implementation.updateTrackers([.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_moveDownloadFolder_shouldMoveStorage() {
        _ = implementation.moveDownloadFolder("/new", [.mock(hash: "A"), .mock(hash: "B")]).wait()
        assertSnapshot(matching: client.requests, as: .requests)
    }
}
