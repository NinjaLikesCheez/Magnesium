import Combine
import ViewModel

enum AddServerViewModelEvent {
    case addServer(ServerType)
    case complete
}

enum AddServerViewEvent {
    case typeSelected(index: Int)
    case cancelSelected
}

struct AddServerViewRepresentation {
    var types: [String]
}

final class AddServerViewModel: ViewModel {
    private let eventSubject = PassthroughSubject<AddServerViewModelEvent, Never>()
    private let serverTypes: [ServerType] = [.deluge, .transmission]
    let view: AddServerViewRepresentation

    var events: AnyPublisher<AddServerViewModelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init() {
        view = .init(types: serverTypes.map(\.localizedString))
    }

    func receive(_ event: AddServerViewEvent) {
        switch event {
        case let .typeSelected(index: index):
            eventSubject.send(.addServer(serverTypes[index]))
        case .cancelSelected:
            eventSubject.send(.complete)
        }
    }
}
