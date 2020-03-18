import Combine
@testable import Magnesium
import XCTest

class TransmissionTorrentDetailViewModelImplementationTests: XCTestCase {
    private var client: MockTransmissionClient!
    private var refresher: MockTorrentRefresher!
    private var implementation: TransmissionTorrentDetailViewModelImplementation!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        client = MockTransmissionClient()
        refresher = MockTorrentRefresher()
        implementation = TransmissionTorrentDetailViewModelImplementation(client: client, refresher: refresher)
    }

    func test_refresh_shouldCallRefresher() {
        implementation.refresh().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &cancellables)
        XCTAssertEqual(refresher.refreshTorrentsCallCount, 1)
    }

    func test_pause_shouldStop() {
        implementation.pause(.mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-stop"])
    }

    func test_resume_shouldStart() {
        implementation.resume(.mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-start"])
    }

    func test_remove_withKeepData_shouldRemove() {
        implementation.remove(.mock(hash: "A"), removeData: false)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-remove"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"delete-local-data":false,"ids":["A"]}"#])
    }

    func test_remove_withRemoveData_shouldRemove() {
        implementation.remove(.mock(hash: "A"), removeData: true)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-remove"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"delete-local-data":true,"ids":["A"]}"#])
    }

    func test_verify_shouldVerify() {
        implementation.verify(.mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-verify"])
    }

    func test_updateTrackers_shouldReannounce() {
        implementation.updateTrackers(for: .mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-reannounce"])
    }

    func test_moveDownloadFolder_shouldSetLocation() {
        implementation.moveDownloadFolder(for: .mock(hash: "A"), to: "/new")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-set-location"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"ids":["A"],"location":"\/new","move":true}"#])
    }
}
