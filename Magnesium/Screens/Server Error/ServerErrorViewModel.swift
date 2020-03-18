import Combine
import ViewModel

enum ServerErrorEvent {
    case showSettings
    case editServer
}

enum ServerErrorViewEvent {
    case settingsSelected
    case editServerSelected
}

final class ServerErrorViewModel: ViewModel {
    private let eventSubject = PassthroughSubject<ServerErrorEvent, Never>()

    var events: AnyPublisher<ServerErrorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func handle(_ event: ServerErrorViewEvent) {
        switch event {
        case .settingsSelected:
            eventSubject.send(.showSettings)
        case .editServerSelected:
            eventSubject.send(.editServer)
        }
    }
}
