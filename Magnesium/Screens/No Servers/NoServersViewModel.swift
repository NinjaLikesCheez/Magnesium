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

    var events: AnyPublisher<NoServersViewModelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func receive(_ event: NoServersViewEvent) {
        switch event {
        case .settingsSelected:
            eventSubject.send(.showSettings)
        case .addServerSelected:
            eventSubject.send(.addServer)
        }
    }
}
