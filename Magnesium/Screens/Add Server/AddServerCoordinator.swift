import Combine
import Coordinator
import Preferences
import UIKit

enum AddServerCoordinatorEvent {
    case complete
}

final class AddServerCoordinator: Coordinator, AlertPresenter {
    private let preferences: Preferences
    private let eventSubject = PassthroughSubject<AddServerCoordinatorEvent, Never>()
    private let viewController: AddServerViewController<AddServerViewModel>
    let received: AnyPublisher<AddServerEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        viewController
    }

    var events: AnyPublisher<AddServerCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(preferences: Preferences) {
        self.preferences = preferences
        let viewModel = AddServerViewModel()
        viewController = AddServerViewController(viewModel: viewModel)
        received = viewModel.events
    }

    func handle(_ event: AddServerEvent) {
        switch event {
        case let .addServer(type):
            showServerSettings(for: type)
        case .complete:
            eventSubject.send(.complete)
        }
    }

    private func showServerSettings(for type: ServerType) {
        let coordinator = ServerSettingsCoordinator(type: type, preferences: preferences)
        addChildCoordinator(coordinator) { [weak self] _, event in
            self?.handle(event)
        }
        viewController.navigationController?.pushViewController(coordinator.presentable.viewController, animated: true)
    }

    // internal for testing
    func handle(_ event: ServerSettingsCoordinatorEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        }
    }
}
