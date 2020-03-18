import Combine
import Coordinator
import Preferences

enum FilterCoordinatorEvent {
    case complete
}

final class FilterCoordinator: Coordinator, AlertPresenter {
    private let navigationController: PresentableNavigationController
    private let eventSubject = PassthroughSubject<FilterCoordinatorEvent, Never>()
    let receivedEvents: AnyPublisher<FilterEvent, Never>
    var childCoordinators = [AnyHashable: AnyCoordinator]()
    var cancellables = Set<AnyCancellable>()

    var presentable: Presentable {
        navigationController
    }

    var events: AnyPublisher<FilterCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(preferences: Preferences, labels: CurrentValueSubject<[StandardLabel], Never>) {
        let viewModel = FilterViewModel(preferences: preferences, labels: labels)
        let viewController = FilterViewController(viewModel: viewModel)
        navigationController = PresentableNavigationController(rootViewController: viewController)
        receivedEvents = viewModel.events
    }

    func handle(_ event: FilterEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert):
            showAlert(alert)
        }
    }
}
