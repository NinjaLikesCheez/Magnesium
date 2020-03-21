import Combine
import Coordinator
import ViewModel

enum ServerSettingsCoordinatorEvent {
    case complete
}

final class ServerSettingsCoordinator: Coordinator, AlertPresenter {
    private let viewController: ServerSettingsViewController<AnyServerSettingsViewModel>
    private let eventSubject = PassthroughSubject<ServerSettingsCoordinatorEvent, Never>()
    let viewModelEvents: AnyPublisher<ServerSettingsViewModelEvent, Never>
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
            viewModel = .init(DelugeSettingsViewModel(server: server))
        case .transmission:
            viewModel = .init(TransmissionSettingsViewModel(server: server))
        }

        viewController = .init(viewModel: viewModel)
        viewModelEvents = viewModel.events
    }

    init(type: ServerType) {
        let viewModel: AnyServerSettingsViewModel
        switch type {
        case .deluge:
            viewModel = .init(DelugeSettingsViewModel())
        case .transmission:
            viewModel = .init(TransmissionSettingsViewModel())
        }

        viewModelEvents = viewModel.events
        viewController = .init(viewModel: viewModel)
    }

    func receive(_ event: ServerSettingsViewModelEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert):
            showAlert(alert)
        }
    }
}
