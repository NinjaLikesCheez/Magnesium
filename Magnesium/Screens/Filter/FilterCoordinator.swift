import Combine
import Coordinator
import Preferences

enum FilterCoordinatorEvent {
    case complete
}

final class FilterCoordinator: Coordinator, AlertPresenter {
    private let navigationController: PresentableNavigationController
    private let eventSubject = PassthroughSubject<FilterCoordinatorEvent, Never>()
    let received: AnyPublisher<FilterEvent, Never>
    var childCoordinators = [AnyHashable: AnyCoordinator]()
    var cancellables = Set<AnyCancellable>()

    var presentable: Presentable {
        return navigationController
    }

    var events: AnyPublisher<FilterCoordinatorEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(preferences: Preferences, labels: CurrentValueSubject<[StandardLabel], Never>) {
        let viewModel = FilterViewModel(preferences: preferences, labels: labels)
        let viewController = FilterViewController(viewModel: viewModel)
        navigationController = PresentableNavigationController(rootViewController: viewController)
        received = viewModel.events
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
