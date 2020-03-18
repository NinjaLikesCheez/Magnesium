import Combine
import ViewModel

enum AddServerEvent {
    case addServer(ServerType)
    case complete
}

enum AddServerViewEvent {
    case typeSelected(index: Int)
    case cancelSelected
}

struct AddServerViewState {
    var types: [String]
}

final class AddServerViewModel: ViewModel {
    private let eventSubject = PassthroughSubject<AddServerEvent, Never>()
    private let serverTypes: [ServerType] = [.deluge, .transmission]
    let state: AddServerViewState

    init() {
        state = AddServerViewState(types: serverTypes.map(\.localizedString))
    }

    var events: AnyPublisher<AddServerEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func handle(_ event: AddServerViewEvent) {
        switch event {
        case let .typeSelected(index: index):
            eventSubject.send(.addServer(serverTypes[index]))
        case .cancelSelected:
            eventSubject.send(.complete)
        }
    }
}
