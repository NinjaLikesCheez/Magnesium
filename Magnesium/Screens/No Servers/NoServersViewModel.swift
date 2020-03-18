import Combine
import ViewModel

enum NoServersEvent {
    case showSettings
    case addServer
}

enum NoServersViewEvent {
    case settingsSelected
    case addServerSelected
}

final class NoServersViewModel: ViewModel, EventEmitter {
    private let eventSubject = PassthroughSubject<NoServersEvent, Never>()
    let state: Void = ()

    var events: AnyPublisher<NoServersEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func handle(_ event: NoServersViewEvent) {
        switch event {
        case .settingsSelected:
            eventSubject.send(.showSettings)
        case .addServerSelected:
            eventSubject.send(.addServer)
        }
    }
}
