import Combine
import Coordinator

enum ServerErrorCoordinatorEvent {
    case showSettings
    case editServer(Server)
}

final class ServerErrorCoordinator: Coordinator {
    private let server: Server
    private let eventSubject = PassthroughSubject<ServerErrorCoordinatorEvent, Never>()
    private let viewController: ServerErrorViewController<ServerErrorViewModel>
    let viewModelEventPublisher: AnyPublisher<ServerErrorViewModelEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        viewController
    }

    var eventPublisher: AnyPublisher<ServerErrorCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(server: Server) {
        self.server = server
        let viewModel = ServerErrorViewModel()
        viewController = .init(viewModel: viewModel)
        viewModelEventPublisher = viewModel.eventPublisher
    }

    func send(_ event: ServerErrorViewModelEvent) {
        switch event {
        case .showSettings:
            eventSubject.send(.showSettings)
        case .editServer:
            eventSubject.send(.editServer(server))
        }
    }
}
