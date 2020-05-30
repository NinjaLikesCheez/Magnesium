import Combine
import ViewModel

enum NoServersViewModelEvent {
    case showSettings
    case addServer
}

enum NoServersViewEvent {
    case settingsSelected
    case addServerSelected
}

final class NoServersViewModel: ViewModel {
    private let eventSubject = PassthroughSubject<NoServersViewModelEvent, Never>()

    var eventPublisher: AnyPublisher<NoServersViewModelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func send(_ event: NoServersViewEvent) {
        switch event {
        case .settingsSelected:
            eventSubject.send(.showSettings)
        case .addServerSelected:
            eventSubject.send(.addServer)
        }
    }
}
