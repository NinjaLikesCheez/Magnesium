import Combine
import Coordinator
import MVVMModels
import Preferences
import UIKit

enum SettingsCoordinatorEvent {
    case complete
}

final class SettingsCoordinator: Coordinator, AlertPresenter {
    private let preferences: Preferences
    private let navigationController: PresentableNavigationController
    private let eventSubject = PassthroughSubject<SettingsCoordinatorEvent, Never>()
    let received: AnyPublisher<SettingsEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        return navigationController
    }

    var events: AnyPublisher<SettingsCoordinatorEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(session: Session, preferences: Preferences) {
        self.preferences = preferences
        let viewModel = SettingsViewModel(session: session, preferences: preferences)
        let viewController = SettingsViewController(viewModel: viewModel)
        navigationController = PresentableNavigationController(rootViewController: viewController)
        received = viewModel.events
    }

    func handle(_ event: SettingsEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert):
            showAlert(alert)
        case let .editServer(server: server):
            showSettings(for: server)
        case .addServer:
            showAddServer()
        case .showRefreshIntervalSettings:
            let viewModel = RefreshIntervalViewModel(preferences: preferences)
            let viewController = RefreshIntervalViewController(viewModel: viewModel)
            return navigationController.pushViewController(viewController, animated: true)
        }
    }

    private func showSettings(for server: Server) {
        let coordinator = ServerSettingsCoordinator(server: server, preferences: preferences)
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            self?.handle(event, from: coordinator)
        }
        navigationController.pushViewController(coordinator.presentable.viewController, animated: true)
    }

    // internal for testing
    func handle<C: Coordinator>(_ event: ServerSettingsCoordinatorEvent, from coordinator: C) {
        switch event {
        case .complete:
            popToPreviousViewController(coordinator.presentable.viewController)
        }
    }

    private func showAddServer() {
        let coordinator = AddServerCoordinator(preferences: preferences)
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            self?.handle(event, from: coordinator)
        }
        navigationController.pushViewController(coordinator.presentable.viewController, animated: true)
    }

    // internal for testing
    func handle<C: Coordinator>(_ event: AddServerCoordinatorEvent, from coordinator: C) {
        switch event {
        case .complete:
            popToPreviousViewController(coordinator.presentable.viewController)
        }
    }

    private func popToPreviousViewController(_ viewController: UIViewController?) {
        guard let viewController = viewController,
            let index = navigationController.viewControllers.firstIndex(of: viewController), index > 0
        else {
            return
        }

        navigationController.popToViewController(navigationController.viewControllers[index - 1], animated: true)
    }
}
