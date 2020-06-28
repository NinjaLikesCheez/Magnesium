import Combine
import CommonModels
import LinkPresentation
@testable import Magnesium
import ViewModel
import XCTest

class TorrentDetailCoordinatorTests: TestCase {
    private var viewModel: MockViewModel!
    private var coordinator: TorrentDetailCoordinator!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        viewModel = MockViewModel()
        coordinator = TorrentDetailCoordinator(viewModel: AnyViewModel(viewModel))
        cancellables = Set()
        coordinator.viewModelEventPublisher
            .sink { [weak coordinator] in coordinator?.send($0) }
            .store(in: &cancellables)
    }

    // MARK: - Presentable

    func test_presentable_shouldBeTorrentDetailViewController() {
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController, TorrentDetailViewController<AnyTorrentDetailViewModel>.self)
    }

    // MARK: - Handle TorrentDetailEvent

    func test_complete_shouldEmitCompleteEvent() throws {
        let event = try coordinator.eventPublisher.first().wait {
            self.viewModel.eventSubject.send(.complete)
        }.singleValue()
        XCTAssertCase(event, .complete)
    }
}

// MARK: - Mocks

private final class MockViewModel: ViewModel {
    let values = TorrentDetailViewValues.mock()
    let eventSubject = PassthroughSubject<TorrentDetailViewModelEvent, Never>()
    var eventPublisher: AnyPublisher<TorrentDetailViewModelEvent, Never> { eventSubject.eraseToAnyPublisher() }
    func send(_ event: TorrentDetailViewEvent) {}
}
