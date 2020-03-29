import Combine
import Deluge
@testable import Magnesium
import XCTest

class DelugeTorrentDetailViewModelImplementationTests: TestCase {
    private var client: MockDelugeClient!
    private var refresher: MockTorrentRefresher!
    private var implementation: DelugeTorrentDetailViewModelImplementation!

    override func setUp() {
        super.setUp()
        client = MockDelugeClient()
        refresher = MockTorrentRefresher()
        implementation = DelugeTorrentDetailViewModelImplementation(client: client, refresher: refresher)
    }

    func test_refresh_shouldCallRefresher() {
        _ = implementation.refresh().wait()
        XCTAssertEqual(refresher.refreshTorrentsCallCount, 1)
    }

    func test_pause_shouldPause() {
        _ = implementation.pause(.mock()).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.pause_torrents"])
    }

    func test_resume_shouldResume() {
        _ = implementation.resume(.mock()).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.resume_torrents"])
    }

    func test_remove_withKeepData_shouldRemove() {
        _ = implementation.remove(.mock(hash: "A"), removeData: false).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.remove_torrents"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"[["A"],false]"#])
    }

    func test_remove_withRemoveData_shouldRemove() {
        _ = implementation.remove(.mock(hash: "A"), removeData: true).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.remove_torrents"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"[["A"],true]"#])
    }

    func test_verify_shouldRecheck() {
        _ = implementation.verify(.mock()).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.force_recheck"])
    }

    func test_setLabel_shouldSetLabels() {
        _ = implementation.setLabel(.mock(), for: .mock()).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["label.set_torrent"])
    }

    func test_updateTrackers_shouldReannounce() {
        _ = implementation.updateTrackers(for: .mock()).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.force_reannounce"])
    }

    func test_moveDownloadFolder_shouldMoveStorage() {
        _ = implementation.moveDownloadFolder(for: .mock(hash: "A"), to: "/new")
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.move_storage"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"[["A"],"\/new"]"#])
    }
}
