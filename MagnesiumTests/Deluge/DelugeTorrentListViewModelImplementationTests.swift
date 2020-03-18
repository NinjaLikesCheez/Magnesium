import Combine
import Deluge
@testable import Magnesium
import Preferences
import XCTest

class DelugeTorrentListViewModelImplementationTests: XCTestCase {
    private var client: MockDelugeClient!
    private var preferences: InMemoryPreferences!
    private var implementation: DelugeTorrentListViewModelImplementation!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        client = MockDelugeClient()
        preferences = InMemoryPreferences()
        implementation = DelugeTorrentListViewModelImplementation(client: client, preferences: preferences)
    }

    func test_refresh_shouldGetCurrentState() {
        implementation.refresh().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["web.update_ui"])
    }

    func test_detailViewModel_shouldReturnExpectedViewModelType() {
        let viewModel = implementation.detailViewModel(
            for: CurrentValueSubject(.mock()),
            labels: CurrentValueSubject([])
        ).base as AnyObject
        let expectedType = StandardTorrentDetailViewModel<DelugeTorrentDetailViewModelImplementation>.self
        guard type(of: viewModel) === expectedType else {
            XCTFail("Unexpected type: \(type(of: viewModel))")
            return
        }
    }

    func test_addLink_withInvalidURL_shouldReturnError() {
        var error: (String, String)?
        implementation.addLink("^").sink { error = $0 }.store(in: &cancellables)
        XCTAssertEqual(error?.0, "Unable to Add Link")
        XCTAssertEqual(error?.1, "That link doesn't appear to be valid.")
    }

    func test_addLink_withMagnetLink_shouldAddMagnetURL() {
        implementation.addLink("magnet:?").sink { _ in }.store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.add_torrent_magnet"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"["magnet:?",{}]"#])
    }

    func test_addLink_withMagnetLink_whenFails_shouldReturnError() {
        client.results.append((
            method: "core.add_torrent_magnet",
            result: Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        var error: (String, String)?
        implementation.addLink("magnet:?").sink { error = $0 }.store(in: &cancellables)
        XCTAssertEqual(error?.0, "Failed to Add Torrent")
    }

    func test_addLink_withRegularLink_shouldAddMagnetURL() {
        implementation.addLink("http://example.com").sink { _ in }.store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.add_torrent_url"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"["http:\/\/example.com",{}]"#])
    }

    func test_addLink_withRegularLink_whenFails_shouldReturnError() {
        client.results.append((
            method: "core.add_torrent_url",
            result: Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        var error: (String, String)?
        implementation.addLink("http://example.com").sink { error = $0 }.store(in: &cancellables)
        XCTAssertEqual(error?.0, "Failed to Add Torrent")
    }

    func test_pause_shouldPause() {
        implementation.pause([.mock(), .mock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.pause_torrents"])
    }

    func test_resume_shouldResume() {
        implementation.resume([.mock(), .mock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.resume_torrents"])
    }

    func test_remove_withKeepData_shouldRemove() {
        implementation.remove([.mock(hash: "A"), .mock(hash: "B")], removeData: false)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.remove_torrents"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"[["A","B"],false]"#])
    }

    func test_remove_withRemoveData_shouldRemove() {
        implementation.remove([.mock(hash: "A"), .mock(hash: "B")], removeData: true)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.remove_torrents"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"[["A","B"],true]"#])
    }

    func test_verify_shouldRecheck() {
        implementation.verify([.mock(), .mock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.force_recheck"])
    }

    func test_setLabel_shouldSetLabels() {
        implementation.setLabel(.mock(name: "label1"), for: [.mock(hash: "A"), .mock(hash: "B")])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["label.set_torrent", "label.set_torrent"])
        XCTAssertEqual(client.requestParamRequest.map(\.args) as? [[String]], [["A", "label1"], ["B", "label1"]])
    }

    func test_updateTrackers_shouldReannounce() {
        implementation.updateTrackers(for: [.mock(), .mock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.force_reannounce"])
    }

    func test_moveDownloadFolder_shouldMoveStorage() {
        implementation.moveDownloadFolder(for: [.mock(hash: "A"), .mock(hash: "B")], to: "/new")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["core.move_storage"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"[["A","B"],"\/new"]"#])
    }

    func test_refreshTorrents_shouldGetCurrentState() {
        implementation.refreshTorrents()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["web.update_ui"])
    }

    func test_refreshTorrents_shouldEmitUpdate() {
        client.results.append((
            method: "web.update_ui",
            result: Just(([], [])).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))
        let expectation = self.expectation(description: "Value received")
        implementation.updated.sink { _ in expectation.fulfill() }.store(in: &cancellables)
        implementation.refreshTorrents()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        waitForExpectations(timeout: 0)
    }
}
