import Combine
import Deluge
@testable import Magnesium
import Preferences
import SnapshotTesting
import Transmission
import XCTest

class AddTorrentFlowTests: TestCase {
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
        viewController = UIViewController()
        session = Session()
        flow = AddTorrentFlow(viewController: viewController, session: session)
    }

    // MARK: Deluge

    func test_add_withDeluge_andFileURL_shouldPerformAddTorrentFileRequest() {
        delugeClient.results.append((
            "core.add_torrent_file",
            Just("").setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))
        session.setServer(.mock(.deluge))

        flow.add(type: .file(URL(fileURLWithPath: "file.torrent")))
        assertSnapshot(matching: delugeClient.requests, as: .requests)
    }

    func test_add_withDeluge_andMagnetURL_shouldPerformAddMagnetRequest() {
        delugeClient.results.append((
            "core.add_torrent_magnet",
            Just("").setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))
        session.setServer(.mock(.deluge))

        flow.add(type: .magnet(URL(string: "magnet:?")!))
        assertSnapshot(matching: delugeClient.requests, as: .requests)
    }

    // MARK: Transmission

    func test_add_withTransmission_andFileURL_shouldPerformAddRequest() {
        session.setServer(.mock(.transmission))

        let url = URL(fileURLWithPath: "file.torrent")
        flow.add(type: .file(url))
        assertSnapshot(matching: transmissionClient.requests, as: .requests)
    }

    func test_add_withTransmission_andMagnetURL_shouldPerformRequest() {
        session.setServer(.mock(.transmission))

        let url = URL(string: "magnet:?")!
        flow.add(type: .magnet(url))
        assertSnapshot(matching: transmissionClient.requests, as: .requests)
    }
}
