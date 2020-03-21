import Combine
import Coordinator
import ViewModel

enum ServerSettingsCoordinatorEvent {
    case complete
}

final class ServerSettingsCoordinator: Coordinator, AlertPresenter {
    private let viewController: ServerSettingsViewController<AnyServerSettingsViewModel>
    private let eventSubject = PassthroughSubject<ServerSettingsCoordinatorEvent, Never>()
    let receivedEvents: AnyPublisher<ServerSettingsEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        viewController
    }

    var events: AnyPublisher<ServerSettingsCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(server: Server) {
        let viewModel: AnyServerSettingsViewModel
        switch server.type {
        case .deluge:
            viewModel = AnyViewModel(DelugeSettingsViewModel(server: server))
        case .transmission:
            viewModel = AnyViewModel(TransmissionSettingsViewModel(server: server))
        }

        viewController = ServerSettingsViewController(viewModel: viewModel)
        receivedEvents = viewModel.events
    }

    init(type: ServerType) {
        let viewModel: AnyServerSettingsViewModel
        switch type {
        case .deluge:
            viewModel = AnyViewModel(DelugeSettingsViewModel())
        case .transmission:
            viewModel = AnyViewModel(TransmissionSettingsViewModel())
        }

        receivedEvents = viewModel.events
        viewController = ServerSettingsViewController(viewModel: viewModel)
    }

    func handle(_ event: ServerSettingsEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert):
            showAlert(alert)
        }
    }
}
