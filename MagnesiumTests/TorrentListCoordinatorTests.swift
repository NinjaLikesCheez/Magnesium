import Combine
import CommonModels
import LinkPresentation
@testable import Magnesium
import Preferences
import ViewModel
import XCTest

class TorrentListCoordinatorTests: TestCase {
    private var window: UIWindow!
    private var viewModel: MockViewModel!
    private var session: Session!
    private var coordinator: TorrentListCoordinator!
    private var cancellables: Set<AnyCancellable>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
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
        XCTAssertType(viewController, TorrentListViewController<AnyTorrentListViewModel>.self)
    }

    // MARK: - Add Torrent

    func test_showAddLink_shouldPresentAlertController() {
        coordinator.showAddLink(subject: .init())
        let viewController = coordinator.presentable.viewController
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Enter a URL")
        XCTAssertEqual(alertController.message, "This can be either a link to a torrent or a magnet link.")
        XCTAssertEqual(alertController.actions.map(\.title), ["Add", "Cancel"])
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
            torrents: [.mock()],
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
        XCTAssertEqual(alertController.actions.map(\.title), ["Add Link", "Add File", "Cancel"])
        XCTAssertEqual(alertController.preferredStyle, .actionSheet)
    }

    func test_filter_shouldPresentFilterViewController() {
        viewModel.eventSubject.send(.filter(
            source: .view(UIView(), rect: .zero),
            labels: Just([]).eraseToAnyPublisher()
        ))
        let viewController = coordinator.presentable.viewController
        let navigationController = viewController.presentedViewController as! UINavigationController
        XCTAssertEqual(navigationController.modalPresentationStyle, .popover)
        XCTAssertType(navigationController.viewControllers.first, FilterViewController<FilterViewModel>.self)
    }

    func test_detail_shouldEmitShowDetailEvent() throws {
        let detailViewModel = AnyViewModel(MockDetailViewModel())
        let event = try coordinator.events.first().wait {
            self.viewModel.eventSubject.send(.detail(viewModel: detailViewModel))
        }.value()
        let viewModel = try extract(case: TorrentListCoordinatorEvent.showDetail, from: event)
        XCTAssertTrue(detailViewModel === viewModel)
    }

    func test_settings_shouldEmitShowSettingsEvent() throws {
        let event = try coordinator.events.first().wait {
            self.viewModel.eventSubject.send(.settings)
        }.value()
        XCTAssertCase(event, .showSettings)
    }

    func test_moveDownloadFolder_shouldPresentAlertController() {
        viewModel.eventSubject.send(.moveDownloadFolder(currentPath: "/path", subject: PassthroughSubject()))
        let viewController = coordinator.presentable.viewController
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Move Download Folder")
        XCTAssertEqual(alertController.actions.map(\.title), ["Save", "Cancel"])
        XCTAssertEqual(alertController.textFields?.count ?? 0, 1)
        let textField = alertController.textFields![0]
        XCTAssertEqual(textField.textContentType, .URL)
        XCTAssertEqual(textField.placeholder, "/downloads")
        XCTAssertEqual(textField.text, "/path")
    }

    func test_torrentsUpdated_shouldEmitTorrentsUpdatedEvent() throws {
        let event = try coordinator.events.first().wait {
            self.viewModel.eventSubject.send(.torrentsUpdated(hashes: []))
        }.value()
        XCTAssertCase(event, type(of: event).torrentsUpdated)
    }

    // MARK: - Handle FilterCoordinatorEvent

    func test_filterCoordinatorEvent_complete_shouldDismiss() {
        let viewController = MockPresentableViewController()
        coordinator.handle(FilterCoordinatorEvent.complete, from: MockCoordinator(viewController: viewController))
        XCTAssertEqual(viewController.dismissCallCount, 1)
        XCTAssertEqual(viewController.dismissParamAnimated, [true])
    }

    // MARK: - TorrentListViewDelegate

    func test_previewForItem_shouldAddDetailChildCoordinator() {
        let viewController = coordinator.previewForItem(at: 0)
        XCTAssertNotNil(viewController)
        XCTAssertEqual(coordinator.childCoordinators.count, 1)
        let childCoordinator = coordinator.childCoordinators.values.first!.base as AnyObject
        XCTAssertType(childCoordinator, TorrentDetailCoordinator<AnyTorrentDetailViewModel>.self)
    }

    func test_commitPreviews_shouldEmitCommitDetailEvent_withSameCoordinator() throws {
        XCTAssertNotNil(coordinator.previewForItem(at: 0))
        let childCoordinator = coordinator.childCoordinators.values.first?.base
            as? TorrentDetailCoordinator<AnyTorrentDetailViewModel>

        let event = try coordinator.events.first().wait {
            self.coordinator.commitPreviewForItem(at: 0)
        }.value()
        let committedCoordinator = try extract(case: type(of: event).commitDetail, from: event)
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
}

// MARK: - Mocks

private final class MockViewModel: ViewModel {
    let values = TorrentListViewValues(
        title: Just("").eraseToAnyPublisher(),
        items: Just([]).eraseToAnyPublisher(),
        isLoading: Just(false).eraseToAnyPublisher(),
        isEditing: Just(false).eraseToAnyPublisher(),
        hasActiveFilters: Just(false).eraseToAnyPublisher(),
        editActionsEnabled: Just(false).eraseToAnyPublisher(),
        status: Just("").eraseToAnyPublisher(),
        detailViewModel: { _ in .init(MockDetailViewModel()) },
        contextMenu: { _ in nil },
        leadingSwipeActionsConfiguration: { _, _ in nil },
        trailingSwipeActionsConfiguration: { _, _ in nil }
    )
    let eventSubject = PassthroughSubject<TorrentListViewModelEvent, Never>()
    var events: AnyPublisher<TorrentListViewModelEvent, Never> { eventSubject.eraseToAnyPublisher() }
    func receive(_ event: TorrentListViewEvent) {}
}

private final class MockDetailViewModel: ViewModel {
    let values = TorrentDetailViewValues(
        hash: "",
        sections: Just([]).eraseToAnyPublisher(),
        isRefreshing: Just(false).eraseToAnyPublisher()
    )
    let events: AnyPublisher<TorrentDetailViewModelEvent, Never> = Empty().eraseToAnyPublisher()
    func receive(_ event: TorrentDetailViewEvent) {}
}
