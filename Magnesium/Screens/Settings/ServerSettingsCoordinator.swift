import Combine
import Coordinator
import Preferences
import ViewModel

enum ServerSettingsCoordinatorEvent {
    case complete
}

final class ServerSettingsCoordinator: Coordinator, AlertPresenter {
    private let viewController: ServerSettingsViewController<AnyServerSettingsViewModel>
    private let eventSubject = PassthroughSubject<ServerSettingsCoordinatorEvent, Never>()
    let received: AnyPublisher<ServerSettingsEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        viewController
    }

    var events: AnyPublisher<ServerSettingsCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(server: Server, preferences: Preferences) {
        let viewModel: AnyServerSettingsViewModel
        switch server.type {
        case .deluge:
            viewModel = AnyEmitterViewModel(DelugeSettingsViewModel(preferences: preferences, server: server))
        case .transmission:
            viewModel = AnyEmitterViewModel(TransmissionSettingsViewModel(preferences: preferences, server: server))
        }

        viewController = ServerSettingsViewController(viewModel: viewModel)
        received = viewModel.events
    }

    init(type: ServerType, preferences: Preferences) {
        let viewModel: AnyServerSettingsViewModel
        switch type {
        case .deluge:
            viewModel = AnyEmitterViewModel(DelugeSettingsViewModel(preferences: preferences))
        case .transmission:
            viewModel = AnyEmitterViewModel(TransmissionSettingsViewModel(preferences: preferences))
        }

        received = viewModel.events
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
