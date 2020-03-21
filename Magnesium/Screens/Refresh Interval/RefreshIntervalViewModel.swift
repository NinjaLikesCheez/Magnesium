import Combine
import Preferences
import ViewModel

enum RefreshIntervalViewEvent {
    case optionSelected(index: Int)
}

struct RefreshIntervalViewState {
    var options: [RefreshIntervalOptionViewState]
}

struct RefreshIntervalOptionViewState {
    var name: String
    var isSelected: AnyPublisher<Bool, Never>
}

final class RefreshIntervalViewModel: ViewModel {
    let state: RefreshIntervalViewState

    private let options: [(Int, String)] = {
        [
            (0, L10n.refreshIntervalNever),
            (2, L10n.refreshIntervalSeconds(2)),
            (5, L10n.refreshIntervalSeconds(5)),
            (10, L10n.refreshIntervalSeconds(10)),
            (30, L10n.refreshIntervalSeconds(30)),
        ]
    }()

    init() {
        let publisher = Current.preferences.valuePublisher(for: .autoRefreshInterval)
        state = RefreshIntervalViewState(options: options.map { option in
            RefreshIntervalOptionViewState(
                name: option.1,
                isSelected: publisher.map { Int($0) == option.0 }.ui().eraseToAnyPublisher()
            )
        })
    }

    func handle(_ event: RefreshIntervalViewEvent) {
        switch event {
        case let .optionSelected(index: index):
            let interval = options[index].0
            Current.preferences[.autoRefreshInterval] = interval
        }
    }
}
