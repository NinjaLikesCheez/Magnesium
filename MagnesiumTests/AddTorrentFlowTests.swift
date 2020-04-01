import Combine
import Deluge
@testable import Magnesium
import Preferences
import SnapshotTesting
import Transmission
import XCTest

class AddTorrentFlowTests: TestCase {
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
        Current.deluge = { _, _ in self.delugeClient }
        Current.transmission = { _, _, _ in self.transmissionClient }
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
        XCTAssertEqual(alertController.actions.map(\.title), ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    // MARK: Deluge

    func test_add_withDeluge_andMissingSettings_shouldPresentAlertController() {
        session.setServer(Server(name: "", type: .deluge, data: Data(), keychainData: nil))

        flow.add(type: .file(URL(fileURLWithPath: "file.torrent")))
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Unable to Add Torrent")
        XCTAssertEqual(alertController.message, "The server settings could not be read.")
        XCTAssertEqual(alertController.actions.map(\.title), ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    func test_add_withDeluge_andFileURL_shouldPerformRequest() {
        delugeClient.results.append((
            "core.add_torrent_file",
            Just("").setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))
        session.setServer(.mock(.deluge))

        flow.add(type: .file(URL(fileURLWithPath: "file.torrent")))
        assertSnapshot(matching: delugeClient.requests, as: .requests)
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
        XCTAssertEqual(alertController.actions.map(\.title), ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    func test_add_withDeluge_andMagnetURL_shouldPerformRequest() {
        delugeClient.results.append((
            "core.add_torrent_magnet",
            Just("").setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))
        session.setServer(.mock(.deluge))

        flow.add(type: .magnet(URL(string: "magnet:?")!))
        assertSnapshot(matching: delugeClient.requests, as: .requests)
    }

    func test_add_withDeluge_andMagnetURL_whenFails_shouldPresentAlertController() {
        delugeClient.results.append(("core.add_torrent_magnet", Fail(error: .unauthenticated).eraseToAnyPublisher()))
        session.setServer(.mock(.deluge))

        flow.add(type: .magnet(URL(string: "magnet:?")!))
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Failed to Add Torrent")
        XCTAssertEqual(alertController.message, DelugeError.unauthenticated.localizedDescription)
        XCTAssertEqual(alertController.actions.map(\.title), ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    // MARK: Transmission

    func test_add_withTransmission_andMissingSettings_shouldPresentAlertController() {
        session.setServer(Server(name: "", type: .transmission, data: Data(), keychainData: nil))

        flow.add(type: .file(URL(fileURLWithPath: "file.torrent")))
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Unable to Add Torrent")
        XCTAssertEqual(alertController.message, "The server settings could not be read.")
        XCTAssertEqual(alertController.actions.map(\.title), ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    func test_add_withTransmission_andFileURL_shouldPerformRequest() {
        session.setServer(.mock(.transmission))

        let url = URL(fileURLWithPath: "file.torrent")
        flow.add(type: .file(url))
        assertSnapshot(matching: transmissionClient.requests, as: .requests)
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
        XCTAssertEqual(alertController.actions.map(\.title), ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    func test_add_withTransmission_andMagnetURL_shouldPerformRequest() {
        session.setServer(.mock(.transmission))

        let url = URL(string: "magnet:?")!
        flow.add(type: .magnet(url))
        assertSnapshot(matching: transmissionClient.requests, as: .requests)
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
        XCTAssertEqual(alertController.actions.map(\.title), ["OK"])
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }
}
