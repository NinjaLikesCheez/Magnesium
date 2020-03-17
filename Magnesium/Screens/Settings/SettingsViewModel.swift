import Combine
import MVVMModels
import Preferences
import ViewModel

enum SettingsEvent {
    case complete
    case alert(Alert)
    case editServer(Server)
    case addServer
    case showRefreshIntervalSettings
}

enum SettingsViewEvent {
    case doneSelected
    case changeServerSelected(source: PopoverSource)
    case serverSelected(index: Int)
    case addServerSelected
    case refreshIntervalSelected
}

struct SettingsViewState {
    var sections: AnyPublisher<[SettingsSection], Never>
}

final class SettingsViewModel: ViewModel, EventEmitter {
    private let session: Session
    private let preferences: Preferences
    private var cancellables = Set<AnyCancellable>()
    private let eventSubject = PassthroughSubject<SettingsEvent, Never>()
    private var sectionsSubject = CurrentValueSubject<[SettingsSection], Never>([])
    let state: SettingsViewState

    var events: AnyPublisher<SettingsEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(session: Session, preferences: Preferences) {
        self.session = session
        self.preferences = preferences
        state = SettingsViewState(sections: sectionsSubject.eraseToAnyPublisher())

        preferences.valueUpdatedPublisher(for: .servers).map { _ in () }
            .merge(with: session.serverPublisher.map { _ in () })
            .merge(with: preferences.valueUpdatedPublisher(for: .autoRefreshInterval).map { _ in () })
            .sink { [weak self] _ in
                self?.updateSections()
            }
            .store(in: &cancellables)

        updateSections()
    }

    func handle(_ event: SettingsViewEvent) {
        switch event {
        case .doneSelected:
            eventSubject.send(.complete)
        case let .changeServerSelected(source):
            handleChangeServerSelected(from: source)
        case let .serverSelected(index):
            let server = preferences.getServers()[index]
            eventSubject.send(.editServer(server))
        case .addServerSelected:
            eventSubject.send(.addServer)
        case .refreshIntervalSelected:
            eventSubject.send(.showRefreshIntervalSettings)
        }
    }

    private func handleChangeServerSelected(from source: PopoverSource) {
        let servers = preferences.getServers()
        var alert = Alert(title: nil, message: nil, style: .actionSheet(source))
        for server in servers {
            alert.addAction(AlertAction(title: server.name, style: .default) {
                self.session.setServer(server)
            })
        }
        alert.addAction(.cancel)
        eventSubject.send(.alert(alert))
    }

    private func updateSections() {
        let servers = preferences.getServers()
        var sections = [SettingsSection]()

        if servers.count > 1, let server = session.server {
            sections.append(SettingsSection(type: .changeServer, items: [.changeServer(server.name)]))
        }

        let serverItems = servers.map { SettingsItem.server(id: $0.id, name: $0.name) }
        sections.append(SettingsSection(type: .servers, items: serverItems + [.addServer]))

        let refreshInterval = preferences[.autoRefreshInterval]
        let localizedRefresh: String
        if refreshInterval <= 0 {
            localizedRefresh = L10n.refreshIntervalNever
        } else {
            localizedRefresh = L10n.refreshIntervalSeconds(Int(refreshInterval))
        }
        sections.append(SettingsSection(type: .general, items: [.refreshInterval(current: localizedRefresh)]))

        sectionsSubject.send(sections)
    }
}
