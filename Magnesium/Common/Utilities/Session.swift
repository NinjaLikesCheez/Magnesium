import Combine
import Preferences

final class Session {
    private let preferences: Preferences
    private let serverSubject = CurrentValueSubject<Server?, Never>(nil)
    private var serverObserver: AnyCancellable?
    private(set) var server: Server?

    var serverPublisher: AnyPublisher<Server?, Never> {
        return serverSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    init(preferences: Preferences) {
        self.preferences = preferences
        _setServer(preferences.getSelectedServer())
    }

    func setServer(_ server: Server) {
        _setServer(server)
    }

    private func _setServer(_ server: Server?) {
        self.server = server
        setupServerObserver()
        serverSubject.send(server)
        if let server = server {
            preferences[.selectedServerID] = server.id
        }
    }

    private func setupServerObserver() {
        guard let server = server else {
            serverObserver = preferences.valueUpdatedPublisher(for: .servers)
                .sink(receiveValue: { [weak self] servers in
                    self?._setServer(servers.first)
                })
            return
        }
        serverObserver = preferences.serverUpdatedPublisher(for: server)
            .sink { [weak self] server in
                if let server = server {
                    self?._setServer(server)
                } else {
                    self?._setServer(self?.preferences.getSelectedServer())
                }
            }
    }
}
