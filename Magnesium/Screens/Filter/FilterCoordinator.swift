import Combine
import Coordinator
import Preferences

enum FilterCoordinatorEvent {
    case complete
}

final class FilterCoordinator: Coordinator, AlertPresenter {
    private let navigationController: PresentableNavigationController
    private let eventSubject = PassthroughSubject<FilterCoordinatorEvent, Never>()
    let viewModelEvents: AnyPublisher<FilterViewModelEvent, Never>
    var childCoordinators = [AnyHashable: AnyCoordinator]()
    var cancellables = Set<AnyCancellable>()

    var presentable: Presentable {
        navigationController
    }

    var events: AnyPublisher<FilterCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(labels: CurrentValueSubject<[StandardLabel], Never>) {
        let viewModel = FilterViewModel(labels: labels)
        let viewController = FilterViewController(viewModel: viewModel)
        navigationController = PresentableNavigationController(rootViewController: viewController)
        viewModelEvents = viewModel.events
    }

    func receive(_ event: FilterViewModelEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert):
            showAlert(alert)
        }
    }
}
