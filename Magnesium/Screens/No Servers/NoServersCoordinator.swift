import Combine
import Coordinator
import Preferences
import UIKit

enum NoServersCoordinatorEvent {
    case showSettings
    case addServer
}

final class NoServersCoordinator: Coordinator {
    private let eventSubject = PassthroughSubject<NoServersCoordinatorEvent, Never>()
    private let viewController: NoServersViewController<NoServersViewModel>
    let received: AnyPublisher<NoServersEvent, Never>
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        return viewController
    }

    var events: AnyPublisher<NoServersCoordinatorEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init() {
        let viewModel = NoServersViewModel()
        viewController = NoServersViewController(viewModel: viewModel)
        received = viewModel.events
    }

    func handle(_ event: NoServersEvent) {
        switch event {
        case .showSettings:
            eventSubject.send(.showSettings)
        case .addServer:
            eventSubject.send(.addServer)
        }
    }
}
