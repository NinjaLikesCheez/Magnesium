import Combine
import CommonModels
import Preferences
import ViewModel

final class SettingsViewModel: ViewModel {
    private let session: Session
    private var cancellables = Set<AnyCancellable>()
    private let eventSubject = PassthroughSubject<SettingsViewModelEvent, Never>()
    private var sectionsSubject = CurrentValueSubject<[SettingsSection], Never>([])
    let values: SettingsViewValues

    var eventPublisher: AnyPublisher<SettingsViewModelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(session: Session) {
        self.session = session
        values = .init(sections: sectionsSubject.ui().eraseToAnyPublisher())

        Current.preferences.updatePublisher(for: .servers).asVoid()
            .merge(with: session.serverPublisher.asVoid())
            .merge(with: Current.preferences.valuePublisher(for: .autoRefreshInterval).asVoid())
            .sink { [weak self] _ in self?.updateSections() }
            .store(in: &cancellables)

        updateSections()
    }

    func send(_ event: SettingsViewEvent) {
        switch event {
        case .doneSelected:
            eventSubject.send(.complete)
        case let .changeServerSelected(source):
            handleChangeServerSelected(from: source)
        case let .serverSelected(index):
            guard let servers = try? Current.preferences.getServers() else { return }
            eventSubject.send(.editServer(servers[index]))
        case .addServerSelected:
            eventSubject.send(.addServer)
        case .refreshIntervalSelected:
            eventSubject.send(.showRefreshIntervalSettings)
        }
    }

    private func handleChangeServerSelected(from source: PopoverSource) {
        let servers = (try? Current.preferences.getServers()) ?? []
        let serverActions = servers.map { server in
            AlertAction(title: server.name, style: .default) {
                self.session.setServer(server)
            }
        }
        eventSubject.send(.alert(.init(style: .actionSheet(source), actions: serverActions + [.cancel])))
    }

    private func updateSections() {
        let servers = (try? Current.preferences.getServers()) ?? []
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
