import Combine
@testable import Magnesium
import Preferences
import Transmission
import XCTest

class TransmissionTorrentListImplementationTests: TestCase {
    private var client: MockTransmissionClient!
    private var implementation: StandardTorrentListImplementation<TransmissionTorrent, Never>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        client = MockTransmissionClient()
        implementation = .transmission(.init(client: client))
    }

    func test_refresh_shouldGetTorrents() {
        _ = implementation.refresh().wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-get"])
    }

    func test_detailViewModel_shouldReturnExpectedViewModelType() {
        let viewModel = implementation.detailViewModel(
            CurrentValueSubject(.mock()),
            CurrentValueSubject([])
        ).base as AnyObject
        XCTAssertType(viewModel, StandardTorrentDetailViewModel<TransmissionTorrentDetailViewModelImplementation>.self)
    }

    func test_addLink_withInvalidURL_shouldReturnError() throws {
        let error = try implementation.addLink("^").wait().error()
        XCTAssertEqual(error.title, "Unable to Add Link")
        XCTAssertEqual(error.message, "That link doesn't appear to be valid.")
    }

    func test_addLink_withMagnetLink_shouldAddURL() {
        _ = implementation.addLink("magnet:?").wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-add"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"filename":"magnet:?"}"#])
    }

    func test_addLink_withRegularLink_shouldAddMagnetURL() {
        _ = implementation.addLink("http://example.com").wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-add"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"filename":"http:\/\/example.com"}"#])
    }

    func test_addLink_whenFails_shouldReturnError() throws {
        client.results.append((
            "torrent-add",
            Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))

        let error = try implementation.addLink("http://example.com").wait().error()
        XCTAssertEqual(error.title, "Failed to Add Torrent")
    }

    func test_pause_shouldStop() {
        _ = implementation.pause([.mock(), .mock()]).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-stop"])
    }

    func test_resume_shouldStart() {
        _ = implementation.resume([.mock(), .mock()]).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-start"])
    }

    func test_remove_withKeepData_shouldRemove() {
        _ = implementation.remove([.mock(hash: "A"), .mock(hash: "B")], false).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-remove"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"delete-local-data":false,"ids":["A","B"]}"#])
    }

    func test_remove_withRemoveData_shouldRemove() {
        _ = implementation.remove([.mock(hash: "A"), .mock(hash: "B")], true).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-remove"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"delete-local-data":true,"ids":["A","B"]}"#])
    }

    func test_verify_shouldVerify() {
        _ = implementation.verify([.mock(), .mock()])
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-verify"])
    }

    func test_updateTrackers_shouldReannounce() {
        _ = implementation.updateTrackers([.mock(), .mock()]).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-reannounce"])
    }

    func test_moveDownloadFolder_shouldSetLocation() {
        _ = implementation.moveDownloadFolder("/new", [.mock(hash: "A"), .mock(hash: "B")]).wait()
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["torrent-set-location"])
        XCTAssertEqual(
            client.requestParamRequest.map(\.argsJSON),
            [#"{"ids":["A","B"],"location":"\/new","move":true}"#]
        )
    }
}
