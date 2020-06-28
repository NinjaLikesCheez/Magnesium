import Combine
import ViewModel

final class AddServerViewModel: ViewModel {
    private let eventSubject = PassthroughSubject<AddServerViewModelEvent, Never>()
    private let serverTypes: [ServerType] = [.deluge, .transmission]
    let values: AddServerViewValues

    var eventPublisher: AnyPublisher<AddServerViewModelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init() {
        values = .init(types: serverTypes.map(\.localizedString))
    }

    func send(_ event: AddServerViewEvent) {
        switch event {
        case let .typeSelected(index: index):
            eventSubject.send(.addServer(serverTypes[index]))
        case .cancelSelected:
            eventSubject.send(.complete)
        }
    }
}
