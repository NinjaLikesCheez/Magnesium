import Combine
import Deluge
@testable import Magnesium
import XCTest

class DelugeTorrentDetailViewModelImplementationTests: XCTestCase {
    private var client: MockDelugeClient!
    private var refresher: MockDelugeRefresher!
    private var implementation: DelugeTorrentDetailViewModelImplementation!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        client = MockDelugeClient()
        refresher = MockDelugeRefresher()
        implementation = DelugeTorrentDetailViewModelImplementation(client: client, refresher: refresher)
    }

    func test_refresh_shouldCallRefresher() {
        implementation.refresh().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &cancellables)
        XCTAssertEqual(refresher.refreshDelugeCallCount, 1)
    }

    func test_pause_shouldPause() {
        implementation.pause(.mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.pause_torrents"])
    }

    func test_resume_shouldResume() {
        implementation.resume(.mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.resume_torrents"])
    }

    func test_remove_withKeepData_shouldRemove() {
        implementation.remove(.mock(hash: "A"), removeData: false)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.remove_torrents"])
        XCTAssertEqual(client.requestParamRequest.map(\.paramsJSON), [#"[["A"],false]"#])
    }

    func test_remove_withRemoveData_shouldRemove() {
        implementation.remove(.mock(hash: "A"), removeData: true)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.remove_torrents"])
        XCTAssertEqual(client.requestParamRequest.map(\.paramsJSON), [#"[["A"],true]"#])
    }

    func test_verify_shouldRecheck() {
        implementation.verify(.mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.force_recheck"])
    }

    func test_setLabel_shouldSetLabels() {
        implementation.setLabel(.mock(), for: .mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["label.set_torrent"])
    }

    func test_updateTrackers_shouldReannounce() {
        implementation.updateTrackers(for: .mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.force_reannounce"])
    }

    func test_moveDownloadFolder_shouldMoveStorage() {
        implementation.moveDownloadFolder(for: .mock(hash: "A"), to: "/new")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.move_storage"])
        XCTAssertEqual(client.requestParamRequest.map(\.paramsJSON), [#"[["A"],"\/new"]"#])
    }
}
