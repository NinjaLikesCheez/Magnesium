import Combine
@testable import Magnesium
import XCTest

class TransmissionTorrentDetailViewModelImplementationTests: TestCase {
    private var client: MockTransmissionClient!
    private var refresher: MockTorrentRefresher!
    private var implementation: TransmissionTorrentDetailViewModelImplementation!

    override func setUp() {
        super.setUp()
        client = MockTransmissionClient()
        refresher = MockTorrentRefresher()
        implementation = TransmissionTorrentDetailViewModelImplementation(client: client, refresher: refresher)
    }

    func test_refresh_shouldCallRefresher() {
        _ = implementation.refresh().wait()
        XCTAssertEqual(refresher.refreshTorrentsCallCount, 1)
    }

    func test_pause_shouldStop() {
        _ = implementation.pause(.mock()).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-stop"])
    }

    func test_resume_shouldStart() {
        _ = implementation.resume(.mock()).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-start"])
    }

    func test_remove_withKeepData_shouldRemove() {
        _ = implementation.remove(.mock(hash: "A"), removeData: false).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-remove"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"delete-local-data":false,"ids":["A"]}"#])
    }

    func test_remove_withRemoveData_shouldRemove() {
        _ = implementation.remove(.mock(hash: "A"), removeData: true).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-remove"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"delete-local-data":true,"ids":["A"]}"#])
    }

    func test_verify_shouldVerify() {
        _ = implementation.verify(.mock()).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-verify"])
    }

    func test_updateTrackers_shouldReannounce() {
        _ = implementation.updateTrackers(for: .mock()).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-reannounce"])
    }

    func test_moveDownloadFolder_shouldSetLocation() {
        _ = implementation.moveDownloadFolder(for: .mock(hash: "A"), to: "/new").wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-set-location"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"ids":["A"],"location":"\/new","move":true}"#])
    }
}
