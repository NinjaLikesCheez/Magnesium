import Combine
import Deluge
@testable import Magnesium
import Preferences
import XCTest

class DelugeTorrentListImplementationTests: TestCase {
    private var client: MockDelugeClient!
    private var implementation: StandardTorrentListImplementation<DelugeTorrent, DelugeLabel>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        client = MockDelugeClient()
        implementation = .deluge(.init(client: client))
    }

    func test_refresh_shouldGetCurrentState() {
        _ = implementation.refresh().wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["web.update_ui"])
    }

    func test_detailViewModel_shouldReturnExpectedViewModelType() {
        let viewModel = implementation.detailViewModel(
            CurrentValueSubject(.mock()),
            CurrentValueSubject([])
        ).base as AnyObject
        XCTAssertType(viewModel, StandardTorrentDetailViewModel<DelugeTorrentDetailViewModelImplementation>.self)
    }

    func test_addLink_withInvalidURL_shouldReturnError() throws {
        let error = try implementation.addLink("^").wait().error()
        XCTAssertEqual(error.title, "Unable to Add Link")
        XCTAssertEqual(error.message, "That link doesn't appear to be valid.")
    }

    func test_addLink_withMagnetLink_shouldAddMagnetURL() {
        _ = implementation.addLink("magnet:?").wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.add_torrent_magnet"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"["magnet:?",{}]"#])
    }

    func test_addLink_withMagnetLink_whenFails_shouldReturnError() throws {
        client.results.append((
            method: "core.add_torrent_magnet",
            result: Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        let error = try implementation.addLink("magnet:?").wait().error()
        XCTAssertEqual(error.title, "Failed to Add Torrent")
    }

    func test_addLink_withRegularLink_shouldAddMagnetURL() {
        _ = implementation.addLink("http://example.com").wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.add_torrent_url"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"["http:\/\/example.com",{}]"#])
    }

    func test_addLink_withRegularLink_whenFails_shouldReturnError() throws {
        client.results.append((
            method: "core.add_torrent_url",
            result: Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        let error = try implementation.addLink("http://example.com").wait().error()
        XCTAssertEqual(error.title, "Failed to Add Torrent")
    }

    func test_pause_shouldPause() {
        _ = implementation.pause([.mock(), .mock()]).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.pause_torrents"])
    }

    func test_resume_shouldResume() {
        _ = implementation.resume([.mock(), .mock()]).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.resume_torrents"])
    }

    func test_remove_withKeepData_shouldRemove() {
        _ = implementation.remove([.mock(hash: "A"), .mock(hash: "B")], false).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.remove_torrents"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"[["A","B"],false]"#])
    }

    func test_remove_withRemoveData_shouldRemove() {
        _ = implementation.remove([.mock(hash: "A"), .mock(hash: "B")], true).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.remove_torrents"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"[["A","B"],true]"#])
    }

    func test_verify_shouldRecheck() {
        _ = implementation.verify([.mock(), .mock()]).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.force_recheck"])
    }

    func test_setLabel_shouldSetLabels() {
        _ = implementation.setLabel(.mock(name: "label1"), [.mock(hash: "A"), .mock(hash: "B")])
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["label.set_torrent", "label.set_torrent"])
        XCTAssertEqual(client.requestParamRequest.map(\.args) as? [[String]], [["A", "label1"], ["B", "label1"]])
    }

    func test_updateTrackers_shouldReannounce() {
        _ = implementation.updateTrackers([.mock(), .mock()]).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.force_reannounce"])
    }

    func test_moveDownloadFolder_shouldMoveStorage() {
        _ = implementation.moveDownloadFolder("/new", [.mock(hash: "A"), .mock(hash: "B")]).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.move_storage"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"[["A","B"],"\/new"]"#])
    }
}
