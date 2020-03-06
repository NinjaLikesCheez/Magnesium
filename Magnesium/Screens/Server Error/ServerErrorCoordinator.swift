import Combine
import Coordinator
import Preferences
import UIKit

enum ServerErrorCoordinatorEvent {
    case showSettings
    case editServer(Server)
}

final class ServerErrorCoordinator: Coordinator {
    private let server: Server
    private let eventSubject = PassthroughSubject<ServerErrorCoordinatorEvent, Never>()
    private let viewController: ServerErrorViewController<ServerErrorViewModel>
    let received: AnyPublisher<ServerErrorEvent, Never>
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        return viewController
    }

    var events: AnyPublisher<ServerErrorCoordinatorEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(server: Server) {
        self.server = server
        let viewModel = ServerErrorViewModel()
        viewController = ServerErrorViewController(viewModel: viewModel)
        received = viewModel.events
    }

    func handle(_ event: ServerErrorEvent) {
        switch event {
        case .showSettings:
            eventSubject.send(.showSettings)
        case .editServer:
            eventSubject.send(.editServer(server))
        }
    }
}
