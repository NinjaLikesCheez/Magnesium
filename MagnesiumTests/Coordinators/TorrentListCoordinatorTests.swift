import Combine
import CommonModels
import EnumTesting
import LinkPresentation
@testable import Magnesium
import Preferences
import ViewModel
import XCTest

class TorrentListCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var viewModel: MockViewModel!
    private var session: Session!
    private var coordinator: TorrentListCoordinator!
    private var cancellables: Set<AnyCancellable>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        Current = .mock
        window = UIWindow()
        viewModel = MockViewModel()
        session = Session()
        coordinator = TorrentListCoordinator(viewModel: AnyTorrentListViewModel(viewModel), session: session)
        cancellables = Set()
        coordinator.viewModelEvents.sink { [weak coordinator] in coordinator?.receive($0) }.store(in: &cancellables)
        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

    // MARK: - Presentable

    func test_presentable_shouldBeTorrentListViewController() {
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController) === TorrentListViewController<AnyTorrentListViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: - Add Torrent

    func test_showAddLink_shouldPresentAlertController() {
        coordinator.showAddLink(subject: .init())
        let viewController = coordinator.presentable.viewController
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Enter a URL")
        XCTAssertEqual(alertController.message, "This can be either a link to a torrent or a magnet link.")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["Add", "Cancel"])
        XCTAssertEqual(alertController.textFields?.count ?? 0, 1)
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    func test_showAddFile_shouldPresentDocumentPickerViewController() {
        coordinator.showAddFile()
        let presentedViewController = coordinator.presentable.viewController.presentedViewController
        XCTAssertType(presentedViewController, UIDocumentPickerViewController.self)
    }

    // MARK: - Handle TorrentListEvent

    func test_alert_shouldPresentAlertController() {
        viewModel.eventSubject.send(.alert(.init(title: "", style: .alert)))
        let presentedViewController = coordinator.presentable.viewController.presentedViewController
        XCTAssertType(presentedViewController, UIAlertController.self)
    }

    func test_activities_shouldPresentActivityViewController() {
        viewModel.eventSubject.send(.activities(
            [],
            torrents: [DelugeTorrent.mock()],
            source: .view(UIView(), rect: .zero)
        ))
        let presentedViewController = coordinator.presentable.viewController.presentedViewController
        XCTAssertType(presentedViewController, UIActivityViewController.self)
    }

    func test_add_shouldPresentAlertController() {
        viewModel.eventSubject.send(.add(source: .view(UIView(), rect: .zero), linkSubject: .init()))
        let viewController = coordinator.presentable.viewController
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Add Torrent")
        XCTAssertEqual(alertController.message, "How would you like to add the torrent?")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["Add Link", "Add File", "Cancel"])
        XCTAssertEqual(alertController.preferredStyle, .actionSheet)
    }

    func test_filter_shouldPresentFilterViewController() {
        viewModel.eventSubject.send(.filter(
            source: .view(UIView(), rect: .zero),
            labels: CurrentValueSubject([])
        ))
        let viewController = coordinator.presentable.viewController
        let navigationController = viewController.presentedViewController as! UINavigationController
        XCTAssertEqual(navigationController.modalPresentationStyle, .popover)
        XCTAssertType(navigationController.viewControllers.first, FilterViewController<FilterViewModel>.self)
    }

    func test_detail_shouldEmitShowDetailEvent() throws {
        let detailViewModel = AnyViewModel(MockDetailViewModel())
        let event = try coordinator.events.wait().first {
            self.viewModel.eventSubject.send(.detail(viewModel: detailViewModel))
        }.unwrap()
        let viewModel = try extract(case: TorrentListCoordinatorEvent.showDetail, from: event)
        XCTAssertTrue(detailViewModel === viewModel)
    }

    func test_settings_shouldEmitShowSettingsEvent() throws {
        let event = try coordinator.events.wait().first {
            self.viewModel.eventSubject.send(.settings)
        }.unwrap()
        XCTAssertCase(TorrentListCoordinatorEvent.showSettings, event)
    }

    func test_moveDownloadFolder_shouldPresentAlertController() {
        viewModel.eventSubject.send(.moveDownloadFolder(currentPath: "/path", subject: PassthroughSubject()))
        let viewController = coordinator.presentable.viewController
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Move Download Folder")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["Save", "Cancel"])
        XCTAssertEqual(alertController.textFields?.count ?? 0, 1)
        let textField = alertController.textFields![0]
        XCTAssertEqual(textField.textContentType, .URL)
        XCTAssertEqual(textField.placeholder, "/downloads")
        XCTAssertEqual(textField.text, "/path")
    }

    func test_torrentsUpdated_shouldEmitTorrentsUpdatedEvent() throws {
        let event = try coordinator.events.wait().first {
            self.viewModel.eventSubject.send(.torrentsUpdated(hashes: []))
        }.unwrap()
        XCTAssertCase(TorrentListCoordinatorEvent.torrentsUpdated, event)
    }

    // MARK: - Handle FilterCoordinatorEvent

    func test_filterCoordinatorEvent_complete_shouldDismiss() {
        let viewController = MockPresentableViewController()
        coordinator.handle(FilterCoordinatorEvent.complete, from: MockCoordinator(viewController: viewController))
        XCTAssertEqual(viewController.dismissCallCount, 1)
        XCTAssertEqual(viewController.dismissParamAnimated, [true])
    }

    // MARK: - TorrentListPreviewProvider

    func test_previewForItem_shouldAddDetailChildCoordinator() {
        let viewController = coordinator.previewForItem(at: 0)
        XCTAssertNotNil(viewController)
        XCTAssertEqual(coordinator.childCoordinators.count, 1)
        let childCoordinator = coordinator.childCoordinators.values.first!.base as AnyObject
        guard type(of: childCoordinator) === TorrentDetailCoordinator<AnyTorrentDetailViewModel>.self else {
            XCTFail("Unexpected coordinator: \(String(describing: coordinator))")
            return
        }
    }

    func test_contextMenuForItem_shouldReturnExpectedMenu() {
        let menu = coordinator.contextMenuForItem(at: 0)
        XCTAssertEqual(menu?.identifier.rawValue, "mock")
    }

    func test_commitPreviews_shouldEmitCommitDetailEvent_withSameCoordinator() throws {
        XCTAssertNotNil(coordinator.previewForItem(at: 0))
        let childCoordinator = coordinator.childCoordinators.values.first?.base
            as? TorrentDetailCoordinator<AnyTorrentDetailViewModel>

        let event = try coordinator.events.wait().first {
            self.coordinator.commitPreviewForItem(at: 0)
        }.unwrap()

        guard case let .commitDetail(committedCoordinator) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertTrue(childCoordinator === committedCoordinator)
    }

    func test_commitPreviewForItem_shouldRemoveChildCoordinator() {
        XCTAssertNotNil(coordinator.previewForItem(at: 0))
        XCTAssertEqual(coordinator.childCoordinators.count, 1)
        var childCoordinator = coordinator.childCoordinators.values.first!.base as AnyObject
        coordinator.commitPreviewForItem(at: 0)
        XCTAssertTrue(coordinator.childCoordinators.isEmpty)
        XCTAssertTrue(isKnownUniquelyReferenced(&childCoordinator))
    }

    func test_cleanupPreviewForItem_shouldRemovePreviewCoordinatorFromCache() {
        XCTAssertNotNil(coordinator.previewForItem(at: 0))
        XCTAssertEqual(coordinator.childCoordinators.count, 1)
        var childCoordinator = coordinator.childCoordinators.values.first!.base as AnyObject
        // remove the child coordinator so the only reference should be the preview cache
        coordinator.childCoordinators.removeAll()
        XCTAssertFalse(isKnownUniquelyReferenced(&childCoordinator))
        coordinator.didDismissPreviewForItem(at: 0)
        let expectation = self.expectation(description: "")
        DispatchQueue.main.async {
            XCTAssertTrue(isKnownUniquelyReferenced(&childCoordinator))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_leadingSwipeActionsConfigurationForItem_shouldReturnExpectedActions() {
        let configuration = coordinator.leadingSwipeActionsConfigurationForItem(
            at: 0,
            source: .view(UIView(), rect: .zero)
        )!
        XCTAssertEqual(configuration.actions.count, 1)
        XCTAssertEqual(configuration.actions[0].title, "leadingMock")
    }

    func test_trailingSwipeActionsConfigurationForItem_shouldReturnExpectedActions() {
        let configuration = coordinator.trailingSwipeActionsConfigurationForItem(
            at: 0,
            source: .view(UIView(), rect: .zero)
        )!
        XCTAssertEqual(configuration.actions.count, 1)
        XCTAssertEqual(configuration.actions[0].title, "trailingMock")
    }
}

// MARK: - Mocks

private final class MockViewModel: ViewModel, TorrentListProvider {
    let view = TorrentListViewRepresentation(
        title: Just("").eraseToAnyPublisher(),
        items: Just([]).eraseToAnyPublisher(),
        isLoading: Just(false).eraseToAnyPublisher(),
        hasActiveFilters: Just(false).eraseToAnyPublisher(),
        editActionsEnabled: Just(false).eraseToAnyPublisher(),
        totalDownloadSpeed: Just("").eraseToAnyPublisher(),
        totalUploadSpeed: Just("").eraseToAnyPublisher()
    )
    let eventSubject = PassthroughSubject<TorrentListViewModelEvent, Never>()
    var events: AnyPublisher<TorrentListViewModelEvent, Never> { eventSubject.eraseToAnyPublisher() }
    func receive(_ event: TorrentListViewEvent) {}

    private(set) var previewViewModels = [AnyTorrentDetailViewModel]()
    func detailViewModelForItem(at index: Int) -> AnyTorrentDetailViewModel? {
        let torrent = CurrentValueSubject<DelugeTorrent, Never>(DelugeTorrent.mock())
        let labels = CurrentValueSubject<[DelugeLabel], Never>([.mock()])
        let client = MockDelugeClient()
        let refresher = MockTorrentRefresher()
        let viewModel = AnyTorrentDetailViewModel(StandardTorrentDetailViewModel(
            implementation: DelugeTorrentDetailViewModelImplementation(client: client, refresher: refresher),
            torrent: torrent,
            labels: labels
        ))
        previewViewModels.append(viewModel)
        return viewModel
    }

    func contextMenuForItem(at index: Int) -> UIMenu? {
        UIMenu(title: "Menu", identifier: UIMenu.Identifier(rawValue: "mock"))
    }

    func leadingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> SwipeActionsConfiguration? {
        SwipeActionsConfiguration(actions: [
            SwipeAction(title: "leadingMock", handler: {}),
        ])
    }

    func trailingSwipeActionsConfigurationForItem(
        at index: Int,
        source: PopoverSource
    ) -> SwipeActionsConfiguration? {
        SwipeActionsConfiguration(actions: [
            SwipeAction(title: "trailingMock", handler: {}),
        ])
    }
}

private final class MockDetailViewModel: ViewModel {
    let view = TorrentDetailViewRepresentation(
        hash: "",
        sections: Just([]).eraseToAnyPublisher(),
        isRefreshing: Just(false).eraseToAnyPublisher()
    )
    let events: AnyPublisher<TorrentDetailViewModelEvent, Never> = Empty().eraseToAnyPublisher()
    func receive(_ event: TorrentDetailViewEvent) {}
}
