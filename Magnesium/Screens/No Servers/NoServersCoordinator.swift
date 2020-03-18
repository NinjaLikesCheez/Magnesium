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
    let receivedEvents: AnyPublisher<NoServersEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        viewController
    }

    var events: AnyPublisher<NoServersCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init() {
        let viewModel = NoServersViewModel()
        viewController = NoServersViewController(viewModel: viewModel)
        receivedEvents = viewModel.events
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
