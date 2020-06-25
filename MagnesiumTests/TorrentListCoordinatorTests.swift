import Combine
import CommonModels
import LinkPresentation
@testable import Magnesium
import Preferences
import ViewModel
import XCTest

class TorrentListCoordinatorTests: TestCase {
    private var viewModel: MockViewModel!
    private var session: Session!
    private var coordinator: TorrentListCoordinator!
    private var cancellables: Set<AnyCancellable>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        viewModel = MockViewModel()
        session = Session()
        coordinator = TorrentListCoordinator(viewModel: AnyTorrentListViewModel(viewModel), session: session)
        cancellables = Set()
        coordinator.viewModelEventPublisher
            .sink { [weak coordinator] in coordinator?.send($0) }
            .store(in: &cancellables)
    }

    // MARK: - Presentable

    func test_presentable_shouldBeTorrentListViewController() {
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController, TorrentListViewController<AnyTorrentListViewModel>.self)
    }

    // MARK: - TorrentListViewModelEvent

    func test_detail_shouldEmitShowDetailEvent() throws {
        let detailViewModel = AnyViewModel(MockDetailViewModel())
        let event = try coordinator.eventPublisher.first().wait {
            self.viewModel.eventSubject.send(.detail(viewModel: detailViewModel))
        }.singleValue()
        let viewModel = try extract(case: TorrentListCoordinatorEvent.showDetail, from: event)
        XCTAssertTrue(detailViewModel === viewModel)
    }

    func test_settings_shouldEmitShowSettingsEvent() throws {
        let event = try coordinator.eventPublisher.first().wait {
            self.viewModel.eventSubject.send(.settings)
        }.singleValue()
        XCTAssertCase(event, .showSettings)
    }

    func test_torrentsUpdated_shouldEmitTorrentsUpdatedEvent() throws {
        let event = try coordinator.eventPublisher.first().wait {
            self.viewModel.eventSubject.send(.torrentsUpdated(hashes: []))
        }.singleValue()
        XCTAssertCase(event, type(of: event).torrentsUpdated)
    }

    // MARK: - FilterCoordinatorEvent

    func test_filterCoordinatorEvent_complete_shouldDismiss() {
        let viewController = MockPresentableViewController()
        coordinator.handle(FilterCoordinatorEvent.complete, from: MockCoordinator(viewController: viewController))
        XCTAssertEqual(viewController.dismissCallCount, 1)
        XCTAssertEqual(viewController.dismissParamAnimated, [true])
    }

    // MARK: - TorrentListViewDelegate

    // TODO:
//    func test_previewForItem_shouldAddDetailChildCoordinator() {
//        let viewController = coordinator.previewForItem(at: 0)
//        XCTAssertNotNil(viewController)
//        XCTAssertEqual(coordinator.childCoordinators.count, 1)
//        let childCoordinator = coordinator.childCoordinators.values.first!.base as AnyObject
//        XCTAssertType(childCoordinator, TorrentDetailCoordinator.self)
//    }
//
//    func test_commitPreviews_shouldEmitCommitDetailEvent_withSameCoordinator() throws {
//        XCTAssertNotNil(coordinator.previewForItem(at: 0))
//        let childCoordinator = coordinator.childCoordinators.values.first?.base as? TorrentDetailCoordinator
//
//        let event = try coordinator.eventPublisher.first().wait {
//            self.coordinator.commitPreviewForItem(at: 0)
//        }.singleValue()
//        let committedCoordinator = try extract(case: type(of: event).commitDetail, from: event)
//        XCTAssertTrue(childCoordinator === committedCoordinator)
//    }
//
//    func test_commitPreviewForItem_shouldRemoveChildCoordinator() {
//        XCTAssertNotNil(coordinator.previewForItem(at: 0))
//        XCTAssertEqual(coordinator.childCoordinators.count, 1)
//        var childCoordinator = coordinator.childCoordinators.values.first!.base as AnyObject
//        coordinator.commitPreviewForItem(at: 0)
//        XCTAssertTrue(coordinator.childCoordinators.isEmpty)
//        XCTAssertTrue(isKnownUniquelyReferenced(&childCoordinator))
//    }
//
//    func test_cleanupPreviewForItem_shouldRemovePreviewCoordinatorFromCache() {
//        XCTAssertNotNil(coordinator.previewForItem(at: 0))
//        XCTAssertEqual(coordinator.childCoordinators.count, 1)
//        var childCoordinator = coordinator.childCoordinators.values.first!.base as AnyObject
//        // remove the child coordinator so the only reference should be the preview cache
//        coordinator.childCoordinators.removeAll()
//        XCTAssertFalse(isKnownUniquelyReferenced(&childCoordinator))
//        coordinator.didDismissPreviewForItem(at: 0)
//        let expectation = self.expectation(description: "")
//        DispatchQueue.main.async {
//            XCTAssertTrue(isKnownUniquelyReferenced(&childCoordinator))
//            expectation.fulfill()
//        }
//        waitForExpectations(timeout: 1)
//    }
}

// MARK: - Mocks

private final class MockViewModel: ViewModel {
    let values = TorrentListViewValues.mock()
    let eventSubject = PassthroughSubject<TorrentListViewModelEvent, Never>()
    var eventPublisher: AnyPublisher<TorrentListViewModelEvent, Never> { eventSubject.eraseToAnyPublisher() }
    func send(_ event: TorrentListViewEvent) {}
}

private final class MockDetailViewModel: ViewModel {
    let values = TorrentDetailViewValues.mock()
    let eventPublisher: AnyPublisher<TorrentDetailViewModelEvent, Never> = Empty().eraseToAnyPublisher()
    func send(_ event: TorrentDetailViewEvent) {}
}
