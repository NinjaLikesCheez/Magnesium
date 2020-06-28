import Combine
import ViewModel

final class ServerErrorViewModel: ViewModel {
    private let eventSubject = PassthroughSubject<ServerErrorViewModelEvent, Never>()

    var eventPublisher: AnyPublisher<ServerErrorViewModelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func send(_ event: ServerErrorViewEvent) {
        switch event {
        case .settingsSelected:
            eventSubject.send(.showSettings)
        case .editServerSelected:
            eventSubject.send(.editServer)
        }
    }
}
