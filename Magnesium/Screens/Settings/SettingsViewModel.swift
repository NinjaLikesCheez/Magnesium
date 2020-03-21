import Combine
import CommonModels
import Preferences
import ViewModel

enum SettingsViewModelEvent {
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

struct SettingsViewRepresentation {
    var sections: AnyPublisher<[SettingsSection], Never>
}

final class SettingsViewModel: ViewModel {
    private let session: Session
    private var cancellables = Set<AnyCancellable>()
    private let eventSubject = PassthroughSubject<SettingsViewModelEvent, Never>()
    private var sectionsSubject = CurrentValueSubject<[SettingsSection], Never>([])
    let view: SettingsViewRepresentation

    var events: AnyPublisher<SettingsViewModelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(session: Session) {
        self.session = session
        view = .init(sections: sectionsSubject.ui().eraseToAnyPublisher())

        Current.preferences.valueUpdatedPublisher(for: .servers).asVoid()
            .merge(with: session.serverPublisher.asVoid())
            .merge(with: Current.preferences.valueUpdatedPublisher(for: .autoRefreshInterval).asVoid())
            .sink { [weak self] _ in
                self?.updateSections()
            }
            .store(in: &cancellables)

        updateSections()
    }

    func receive(_ event: SettingsViewEvent) {
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
        eventSubject.send(.alert(.init(style: .actionSheet(source), actions: serverActions + [.cancel])))
    }

    private func updateSections() {
        let servers = Current.preferences.getServers()
        var sections = [SettingsSection]()

        if servers.count > 1, let server = session.server {
            sections.append(.init(type: .changeServer, items: [.changeServer(server.name)]))
        }

        let serverItems = servers.map { SettingsItem.server(id: $0.id, name: $0.name) }
        sections.append(.init(type: .servers, items: serverItems + [.addServer]))

        let refreshInterval = Current.preferences[.autoRefreshInterval]
        let localizedRefresh: String
        if refreshInterval <= 0 {
            localizedRefresh = L10n.refreshIntervalNever
        } else {
            localizedRefresh = L10n.refreshIntervalSeconds(Int(refreshInterval))
        }
        sections.append(.init(type: .general, items: [.refreshInterval(current: localizedRefresh)]))

        sectionsSubject.send(sections)
    }
}
