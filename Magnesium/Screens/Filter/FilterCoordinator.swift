import Combine
import Coordinator

enum FilterCoordinatorEvent {
    case complete
}

final class FilterCoordinator: Coordinator {
    private let navigationController: PresentableNavigationController
    private let eventSubject = PassthroughSubject<FilterCoordinatorEvent, Never>()
    let viewModelEventPublisher: AnyPublisher<FilterViewModelEvent, Never>
    var childCoordinators = [AnyHashable: AnyCoordinator]()
    var cancellables = Set<AnyCancellable>()

    var presentable: Presentable {
        navigationController
    }

    var eventPublisher: AnyPublisher<FilterCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(labels: AnyPublisher<[StandardLabel], Never>) {
        let viewModel = FilterViewModel(labels: labels)
        let viewController = FilterViewController(viewModel: viewModel)
        navigationController = .init(rootViewController: viewController)
        viewModelEventPublisher = viewModel.eventPublisher
    }

    func send(_ event: FilterViewModelEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert):
            showAlert(alert)
        }
    }
}
