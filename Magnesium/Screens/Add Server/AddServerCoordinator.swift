import Combine
import Coordinator
import UIKit

enum AddServerCoordinatorEvent {
    case complete
}

final class AddServerCoordinator: Coordinator {
    private let eventSubject = PassthroughSubject<AddServerCoordinatorEvent, Never>()
    private let viewController: AddServerViewController<AddServerViewModel>
    let viewModelEvents: AnyPublisher<AddServerViewModelEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        viewController
    }

    var events: AnyPublisher<AddServerCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init() {
        let viewModel = AddServerViewModel()
        viewController = .init(viewModel: viewModel)
        viewModelEvents = viewModel.events
    }

    func receive(_ event: AddServerViewModelEvent) {
        switch event {
        case let .addServer(type):
            showServerSettings(for: type)
        case .complete:
            eventSubject.send(.complete)
        }
    }

    private func showServerSettings(for type: ServerType) {
        let coordinator = ServerSettingsCoordinator(type: type)
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
