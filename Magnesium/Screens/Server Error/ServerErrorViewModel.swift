import Combine
import ViewModel

enum ServerErrorViewModelEvent {
    case showSettings
    case editServer
}

enum ServerErrorViewEvent {
    case settingsSelected
    case editServerSelected
}

final class ServerErrorViewModel: ViewModel {
    private let eventSubject = PassthroughSubject<ServerErrorViewModelEvent, Never>()

    var events: AnyPublisher<ServerErrorViewModelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func receive(_ event: ServerErrorViewEvent) {
        switch event {
        case .settingsSelected:
            eventSubject.send(.showSettings)
        case .editServerSelected:
            eventSubject.send(.editServer)
        }
    }
}
