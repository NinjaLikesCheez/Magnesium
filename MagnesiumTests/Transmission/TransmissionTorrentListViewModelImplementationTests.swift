import Combine
@testable import Magnesium
import Preferences
import Transmission
import XCTest

class TransmissionTorrentListViewModelImplementationTests: XCTestCase {
    private var client: MockTransmissionClient!
    private var preferences: InMemoryPreferences!
    private var implementation: TransmissionTorrentListViewModelImplementation!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        client = MockTransmissionClient()
        preferences = InMemoryPreferences()
        implementation = TransmissionTorrentListViewModelImplementation(client: client, preferences: preferences)
    }

    func test_refresh_shouldGetTorrents() {
        implementation.refresh().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &observers)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-get"])
    }

    func test_detailViewModel_shouldReturnExpectedViewModelType() {
        let viewModel = implementation.detailViewModel(
            for: CurrentValueSubject(.mock()),
            labels: CurrentValueSubject([])
        ).base as AnyObject
        let expectedType = StandardTorrentDetailViewModel<TransmissionTorrentDetailViewModelImplementation>.self
        guard type(of: viewModel) === expectedType else {
            XCTFail("Unexpected type: \(type(of: viewModel))")
            return
        }
    }

    func test_addLink_withInvalidURL_shouldReturnError() {
        var error: (String, String)?
        implementation.addLink("^").sink { error = $0 }.store(in: &observers)
        XCTAssertEqual(error?.0, "Unable to Add Link")
        XCTAssertEqual(error?.1, "That link doesn't appear to be valid.")
    }

    func test_addLink_withMagnetLink_shouldAddURL() {
        implementation.addLink("magnet:?").sink { _ in }.store(in: &observers)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-add"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"filename":"magnet:?"}"#])
    }

    func test_addLink_withRegularLink_shouldAddMagnetURL() {
        implementation.addLink("http://example.com").sink { _ in }.store(in: &observers)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-add"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"filename":"http:\/\/example.com"}"#])
    }

    func test_addLink_whenFails_shouldReturnError() {
        client.results.append((
            "torrent-add",
            Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))

        var error: (String, String)?
        implementation.addLink("http://example.com").sink { error = $0 }.store(in: &observers)
        XCTAssertEqual(error?.0, "Failed to Add Torrent")
    }

    func test_pause_shouldStop() {
        implementation.pause([.mock(), .mock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-stop"])
    }

    func test_resume_shouldStart() {
        implementation.resume([.mock(), .mock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-start"])
    }

    func test_remove_withKeepData_shouldRemove() {
        implementation.remove([.mock(hash: "A"), .mock(hash: "B")], removeData: false)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-remove"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"delete-local-data":false,"ids":["A","B"]}"#])
    }

    func test_remove_withRemoveData_shouldRemove() {
        implementation.remove([.mock(hash: "A"), .mock(hash: "B")], removeData: true)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-remove"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"delete-local-data":true,"ids":["A","B"]}"#])
    }

    func test_verify_shouldVerify() {
        implementation.verify([.mock(), .mock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-verify"])
    }

    func test_updateTrackers_shouldReannounce() {
        implementation.updateTrackers(for: [.mock(), .mock()])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-reannounce"])
    }

    func test_moveDownloadFolder_shouldMove() {
        implementation.moveDownloadFolder(for: [.mock(hash: "A"), .mock(hash: "B")], to: "/new")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-set-location"])
        XCTAssertEqual(
            client.requestParamRequest.map(\.argsJSON),
            [#"{"ids":["A","B"],"location":"\/new","move":true}"#]
        )
    }

    func test_refreshTransmission_shouldGetTorrents() {
        implementation.refreshTransmission()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-get"])
    }

    func test_refreshTransmission_shouldEmitUpdate() {
        client.results.append((
            method: "torrent-get",
            result: Just([]).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
        ))

        let expectation = self.expectation(description: "Value received")
        implementation.updated.sink { _ in expectation.fulfill() }.store(in: &observers)
        implementation.refreshTransmission()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        waitForExpectations(timeout: 0)
    }
}
