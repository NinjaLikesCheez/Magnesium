import Combine
import Coordinator

enum NoServersCoordinatorEvent {
    case showSettings
    case addServer
}

final class NoServersCoordinator: Coordinator {
    private let eventSubject = PassthroughSubject<NoServersCoordinatorEvent, Never>()
    private let viewController: NoServersViewController<NoServersViewModel>
    let viewModelEventPublisher: AnyPublisher<NoServersViewModelEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        viewController
    }

    var eventPublisher: AnyPublisher<NoServersCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init() {
        let viewModel = NoServersViewModel()
        viewController = .init(viewModel: viewModel)
        viewModelEventPublisher = viewModel.eventPublisher
    }

    func send(_ event: NoServersViewModelEvent) {
        switch event {
        case .showSettings:
            eventSubject.send(.showSettings)
        case .addServer:
            eventSubject.send(.addServer)
        }
    }
}
