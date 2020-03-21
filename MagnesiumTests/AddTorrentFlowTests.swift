import Combine
import Deluge
@testable import Magnesium
import Preferences
import Transmission
import XCTest

class AddTorrentFlowTests: XCTestCase {
    private var window: UIWindow!
    private var viewController: UIViewController!
    private var session: Session!
    private var flow: AddTorrentFlow!
    private var delugeClient: MockDelugeClient!
    private var transmissionClient: MockTransmissionClient!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        delugeClient = MockDelugeClient()
        transmissionClient = MockTransmissionClient()
        Current = .mock(
            deluge: { _, _ in self.delugeClient },
            transmission: { _, _, _ in self.transmissionClient }
        )
        window = UIWindow()
        viewController = UIViewController()
        session = Session()
        flow = AddTorrentFlow(viewController: viewController, session: session)
        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }

    func test_add_withNoServer_shouldPresentAlertController() {
        flow.add(type: .file(URL(fileURLWithPath: "file.torrent")))
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Unable to Add Torrent")
        XCTAssertEqual(alertController.message, "There are no servers.")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    // MARK: Deluge

    func test_add_withDeluge_andMissingSettings_shouldPresentAlertController() {
        session.setServer(Server(name: "", type: .deluge, data: Data(), keychainData: nil))

        flow.add(type: .file(URL(fileURLWithPath: "file.torrent")))
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Unable to Add Torrent")
        XCTAssertEqual(alertController.message, "The server settings could not be read.")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    func test_add_withDeluge_andFileURL_shouldPerformRequest() {
        delugeClient.results.append((
            "core.add_torrent_file",
            Just("").setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))
        session.setServer(.mock(.deluge))

        flow.add(type: .file(URL(fileURLWithPath: "file.torrent")))
        XCTAssertEqual(delugeClient.requestParamRequest.map(\.method), ["core.add_torrent_file"])
        XCTAssertEqual(delugeClient.requestParamRequest.map(\.argsJSON), [#"["file.torrent","",{}]"#])
    }

    func test_add_withDeluge_andFileURL_whenFails_shouldPresentAlertController() {
        delugeClient.results.append((
            "core.add_torrent_file",
            Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        session.setServer(.mock(.deluge))

        flow.add(type: .file(URL(fileURLWithPath: "file.torrent")))
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Failed to Add Torrent")
        XCTAssertEqual(alertController.message, DelugeError.unauthenticated.localizedDescription)
        XCTAssertEqual(alertController.actions.map { $0.title }, ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    func test_add_withDeluge_andMagnetURL_shouldPerformRequest() {
        delugeClient.results.append((
            "core.add_torrent_magnet",
            Just("").setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))
        session.setServer(.mock(.deluge))

        flow.add(type: .magnet(URL(string: "magnet:?")!))
        XCTAssertEqual(delugeClient.requestCallCount, 1)
        XCTAssertEqual(delugeClient.requestParamRequest.first?.method, "core.add_torrent_magnet")
        XCTAssertEqual(delugeClient.requestParamRequest.first?.argsJSON, #"["magnet:?",{}]"#)
    }

    func test_add_withDeluge_andMagnetURL_whenFails_shouldPresentAlertController() {
        delugeClient.results.append(("core.add_torrent_magnet", Fail(error: .unauthenticated).eraseToAnyPublisher()))
        session.setServer(.mock(.deluge))

        flow.add(type: .magnet(URL(string: "magnet:?")!))
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Failed to Add Torrent")
        XCTAssertEqual(alertController.message, DelugeError.unauthenticated.localizedDescription)
        XCTAssertEqual(alertController.actions.map { $0.title }, ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    // MARK: Transmission

    func test_add_withTransmission_andMissingSettings_shouldPresentAlertController() {
        session.setServer(Server(name: "", type: .transmission, data: Data(), keychainData: nil))

        flow.add(type: .file(URL(fileURLWithPath: "file.torrent")))
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Unable to Add Torrent")
        XCTAssertEqual(alertController.message, "The server settings could not be read.")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    func test_add_withTransmission_andFileURL_shouldPerformRequest() {
        session.setServer(.mock(.transmission))

        let url = URL(fileURLWithPath: "file.torrent")
        flow.add(type: .file(url))
        XCTAssertEqual(transmissionClient.requestParamRequest.map(\.method), ["torrent-add"])
        XCTAssertEqual(transmissionClient.requestParamRequest.map(\.argsJSON), [#"{"metainfo":""}"#])
    }

    func test_add_withTransmission_andFileURL_whenFails_shouldPresentAlertController() {
        transmissionClient.results.append((
            "torrent-add",
            Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        session.setServer(.mock(.transmission))

        flow.add(type: .file(URL(fileURLWithPath: "file.torrent")))
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Failed to Add Torrent")
        XCTAssertEqual(alertController.message, TransmissionError.unauthenticated.localizedDescription)
        XCTAssertEqual(alertController.actions.map { $0.title }, ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    func test_add_withTransmission_andMagnetURL_shouldPerformRequest() {
        session.setServer(.mock(.transmission))

        let url = URL(string: "magnet:?")!
        flow.add(type: .magnet(url))
        XCTAssertEqual(transmissionClient.requestParamRequest.map(\.method), ["torrent-add"])
        XCTAssertEqual(transmissionClient.requestParamRequest.map(\.argsJSON), [#"{"filename":"magnet:?"}"#])
    }

    func test_add_withTransmission_andMagnetURL_whenFails_shouldPresentAlertController() {
        transmissionClient.results.append((
            "torrent-add",
            Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        session.setServer(.mock(.transmission))

        flow.add(type: .magnet(URL(string: "magnet:?")!))
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Failed to Add Torrent")
        XCTAssertEqual(alertController.message, TransmissionError.unauthenticated.localizedDescription)
        XCTAssertEqual(alertController.actions.map { $0.title }, ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }
}
