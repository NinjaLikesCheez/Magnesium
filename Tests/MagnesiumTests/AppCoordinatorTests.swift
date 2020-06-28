import Combine
import Coordinator
@testable import Magnesium
import Preferences
import ViewModel
import XCTest

class AppCoordinatorTests: TestCase {
    private var window: UIWindow!
    private var session: Session!
    private var splitViewController: MockSplitViewController!
    private var coordinator: AppCoordinator!

    override func setUp() {
        super.setUp()
        window = UIWindow()
        session = Session()
        splitViewController = MockSplitViewController()
        coordinator = AppCoordinator(window: window, session: session, splitViewController: splitViewController)
    }

    func test_presentable_shouldBeSplitViewController() {
        XCTAssertEqual(splitViewController, coordinator.presentable.viewController)
    }

    func test_masterViewController_whenNoServers_shouldBeExpectedViewController() {
        let navigationController = splitViewController.viewControllers[0] as! UINavigationController
        XCTAssertType(navigationController.viewControllers.first, NoServersViewController<NoServersViewModel>.self)
    }

    func test_masterViewController_whenServerSettingsInvalid_shouldBeExpectedViewController() {
        let navigationController = splitViewController.viewControllers[0] as! UINavigationController
        session.setServer(Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        XCTAssertType(navigationController.viewControllers.first, ServerErrorViewController<ServerErrorViewModel>.self)
    }

    func test_masterViewController_whenServerChanged_shouldBeChanged() {
        let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        session.setServer(.mock(.transmission))
        let firstViewController = masterNavigationController.viewControllers[0]
        session.setServer(.mock(.deluge))
        let secondViewController = masterNavigationController.viewControllers[0]
        XCTAssertNotEqual(firstViewController, secondViewController)
    }

    func test_addFileURL_shouldPresentAlertController() {
        session.setServer(.mock(.transmission))
        coordinator.add(fileURL: URL(fileURLWithPath: "/file.torrent", isDirectory: false))
        let alertController = splitViewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Add to MockServer")
        XCTAssertEqual(alertController.message, "file.torrent")
        XCTAssertEqual(alertController.actions.map(\.title), ["Add Torrent", "Cancel"])
    }

    func test_addMagnetURL_shouldPresentAlertController() {
        session.setServer(.mock(.transmission))
        coordinator.add(magnetURL: URL(string: "magnet:?")!)
        let alertController = splitViewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Add to MockServer")
        XCTAssertEqual(alertController.message, "magnet:?")
        XCTAssertEqual(alertController.actions.map(\.title), ["Add Torrent", "Cancel"])
    }

    // MARK: - ServerErrorCoordinatorEvent

    func test_serverErrorCoordinatorEvent_showSettings_shouldShowSettings() throws {
        coordinator.handle(ServerErrorCoordinatorEvent.showSettings)
        let navigationController = splitViewController.presentedViewController as! UINavigationController
        XCTAssertType(navigationController.viewControllers.first, SettingsViewController<SettingsViewModel>.self)
    }

    func test_serverErrorCoordinatorEvent_editServer_shouldShowServerSettings() throws {
        coordinator.handle(ServerErrorCoordinatorEvent.editServer(.mock(.transmission)))
        let navigationController = splitViewController.presentedViewController as! UINavigationController
        XCTAssertType(
            navigationController.viewControllers.first,
            ServerSettingsViewController<AnyServerSettingsViewModel>.self
        )
    }

    // MARK: - NoServersCoordinatorEvent

    func test_noServersCoordinatorEvent_showSettings_shouldShowSettings() throws {
        coordinator.handle(NoServersCoordinatorEvent.showSettings)
        let navigationController = splitViewController.presentedViewController as! UINavigationController
        XCTAssertType(navigationController.viewControllers.first, SettingsViewController<SettingsViewModel>.self)
    }

    func test_noServersCoordinatorEvent_addServer_shouldShowAddServer() throws {
        coordinator.handle(NoServersCoordinatorEvent.addServer)
        let navigationController = splitViewController.presentedViewController as! UINavigationController
        XCTAssertType(navigationController.viewControllers.first, AddServerViewController<AddServerViewModel>.self)
    }

    // MARK: - TorrentListCoordinatorEvent

    func test_listCoordinatorEvent_showSettings_shouldShowSettings() throws {
        coordinator.handle(TorrentListCoordinatorEvent.showSettings)
        let navigationController = splitViewController.presentedViewController as! UINavigationController
        XCTAssertType(navigationController.viewControllers.first, SettingsViewController<SettingsViewModel>.self)
    }

    func test_listCoordinatorEvent_showDetail_shouldShowDetail() throws {
        coordinator.handle(.showDetail(viewModel: AnyViewModel(MockTorrentDetailViewModel())))
        let navigationController = splitViewController.detailViewController as! UINavigationController
        XCTAssertType(
            navigationController.viewControllers.first,
            TorrentDetailViewController<AnyTorrentDetailViewModel>.self
        )
    }

    func test_listCoordinatorEvent_commitDetail_shouldCommitDetail() throws {
        let viewModel = AnyTorrentDetailViewModel(MockTorrentDetailViewModel())
        let detailCoordinator = TorrentDetailCoordinator(viewModel: viewModel)
        coordinator.handle(TorrentListCoordinatorEvent.commitDetail(coordinator: detailCoordinator))
        let navigationController = splitViewController.detailViewController as! UINavigationController
        XCTAssertType(
            navigationController.viewControllers.first,
            TorrentDetailViewController<AnyTorrentDetailViewModel>.self
        )
    }

    func test_listCoordinatorEvent_torrentsUpdated_whenHashNotRemoved_shouldDismissDetail() throws {
        coordinator.handle(.showDetail(viewModel: AnyViewModel(MockTorrentDetailViewModel(.mock(hash: "A")))))
        let previousDetailViewController = splitViewController.detailViewController
        XCTAssertNotNil(previousDetailViewController)
        coordinator.handle(.torrentsUpdated(hashes: ["A", "B"]))
        XCTAssertEqual(splitViewController.detailViewController, previousDetailViewController)
    }

    func test_listCoordinatorEvent_torrentsUpdated_whenHashRemoved_shouldDismissDetail() throws {
        coordinator.handle(.showDetail(viewModel: AnyViewModel(MockTorrentDetailViewModel(.mock(hash: "A")))))
        let previousDetailViewController = splitViewController.detailViewController
        XCTAssertNotNil(previousDetailViewController)
        coordinator.handle(.torrentsUpdated(hashes: ["B"]))
        XCTAssertNotEqual(splitViewController.detailViewController, previousDetailViewController)
    }

    // MARK: - SettingsCoordinatorEvent

    func test_settingsCoordinator_completeEvent_shouldDismiss() {
        let viewController = MockPresentableViewController()
        coordinator.handle(SettingsCoordinatorEvent.complete, from: MockCoordinator(viewController: viewController))
        XCTAssertEqual(viewController.dismissCallCount, 1)
        XCTAssertEqual(viewController.dismissParamAnimated, [true])
    }

    // MARK: - AddServerCoordinatorEvent

    func test_addServerCoordinatorEvent_complete_shouldDismiss() {
        let viewController = MockPresentableViewController()
        coordinator.handle(AddServerCoordinatorEvent.complete, from: MockCoordinator(viewController: viewController))
        XCTAssertEqual(viewController.dismissCallCount, 1)
        XCTAssertEqual(viewController.dismissParamAnimated, [true])
    }

    // MARK: - ServerSettingsCoordinatorEvent

    func test_serverSettingsCoordinatorEvent_complete_shouldDismiss() {
        let viewController = MockPresentableViewController()
        coordinator.handle(
            ServerSettingsCoordinatorEvent.complete,
            from: MockCoordinator(viewController: viewController)
        )
        XCTAssertEqual(viewController.dismissCallCount, 1)
        XCTAssertEqual(viewController.dismissParamAnimated, [true])
    }

    // MARK: - TorrentDetailCoordinatorEvent

    func test_detailCoordinator_completeEvent_shouldDismiss() {
        let previousDetailViewController = splitViewController.detailViewController
        XCTAssertNotNil(previousDetailViewController)
        coordinator.handle(
            TorrentDetailCoordinatorEvent.complete,
            from: MockCoordinator(viewController: MockPresentableViewController())
        )
        XCTAssertNotEqual(splitViewController.detailViewController, previousDetailViewController)
    }
}

// MARK: - Mocks

private final class MockSplitViewController: PresentableSplitViewController {
    private(set) var detailViewController: UIViewController?

    override var viewControllers: [UIViewController] {
        didSet {
            if viewControllers.count > 1 {
                detailViewController = viewControllers[1]
            }
        }
    }

    override func showDetailViewController(_ viewController: UIViewController, sender: Any?) {
        detailViewController = viewController
    }
}

private final class MockTorrentDetailViewModel: ViewModel {
    let values: TorrentDetailViewValues
    let eventPublisher: AnyPublisher<TorrentDetailViewModelEvent, Never> = Empty().eraseToAnyPublisher()

    init(_ values: TorrentDetailViewValues = .mock()) {
        self.values = values
    }

    func send(_ event: TorrentDetailViewEvent) {}
}
