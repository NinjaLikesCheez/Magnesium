import Combine
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

final class SettingsViewModel: ViewModel {
    private let session: Session
    private var cancellables = Set<AnyCancellable>()
    private let eventSubject = PassthroughSubject<SettingsEvent, Never>()
    private var sectionsSubject = CurrentValueSubject<[SettingsSection], Never>([])
    let state: SettingsViewState

    var events: AnyPublisher<SettingsEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(session: Session) {
        self.session = session
        state = SettingsViewState(sections: sectionsSubject.eraseToAnyPublisher())

        Current.preferences.valueUpdatedPublisher(for: .servers).map { _ in () }
            .merge(with: session.serverPublisher.map { _ in () })
            .merge(with: Current.preferences.valueUpdatedPublisher(for: .autoRefreshInterval).map { _ in () })
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
            let server = Current.preferences.getServers()[index]
            eventSubject.send(.editServer(server))
        case .addServerSelected:
            eventSubject.send(.addServer)
        case .refreshIntervalSelected:
            eventSubject.send(.showRefreshIntervalSettings)
        }
    }

    private func handleChangeServerSelected(from source: PopoverSource) {
        let servers = Current.preferences.getServers()
        let serverActions = servers.map { server in
            AlertAction(title: server.name, style: .default) {
                self.session.setServer(server)
            }
        }
        let alert = Alert(title: nil, message: nil, style: .actionSheet(source), actions: serverActions + [.cancel])
        eventSubject.send(.alert(alert))
    }

    private func updateSections() {
        let servers = Current.preferences.getServers()
        var sections = [SettingsSection]()

        if servers.count > 1, let server = session.server {
            sections.append(SettingsSection(type: .changeServer, items: [.changeServer(server.name)]))
        }

        let serverItems = servers.map { SettingsItem.server(id: $0.id, name: $0.name) }
        sections.append(SettingsSection(type: .servers, items: serverItems + [.addServer]))

        let refreshInterval = Current.preferences[.autoRefreshInterval]
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
