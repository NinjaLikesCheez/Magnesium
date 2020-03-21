import Combine
import Coordinator
import Preferences

enum ServerErrorCoordinatorEvent {
    case showSettings
    case editServer(Server)
}

final class ServerErrorCoordinator: Coordinator {
    private let server: Server
    private let eventSubject = PassthroughSubject<ServerErrorCoordinatorEvent, Never>()
    private let viewController: ServerErrorViewController<ServerErrorViewModel>
    let viewModelEvents: AnyPublisher<ServerErrorViewModelEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        viewController
    }

    var events: AnyPublisher<ServerErrorCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(server: Server) {
        self.server = server
        let viewModel = ServerErrorViewModel()
        viewController = ServerErrorViewController(viewModel: viewModel)
        viewModelEvents = viewModel.events
    }

    func receive(_ event: ServerErrorViewModelEvent) {
        switch event {
        case .showSettings:
            eventSubject.send(.showSettings)
        case .editServer:
            eventSubject.send(.editServer(server))
        }
    }
}
