import Combine
import Preferences

final class Session {
    private let serverSubject = CurrentValueSubject<Server?, Never>(nil)
    private var serverObserver: AnyCancellable?
    private(set) var server: Server?

    var serverPublisher: AnyPublisher<Server?, Never> {
        serverSubject.removeDuplicates().eraseToAnyPublisher()
    }

    init() {
        _setServer(Current.preferences.getSelectedServer())
    }

    func setServer(_ server: Server) {
        _setServer(server)
    }

    private func _setServer(_ server: Server?) {
        self.server = server
        setupServerObserver()
        serverSubject.send(server)
        if let server = server {
            Current.preferences[.selectedServerID] = server.id
        }
    }

    private func setupServerObserver() {
        guard let server = server else {
            serverObserver = Current.preferences.valueUpdatedPublisher(for: .servers).sink { [weak self] servers in
                self?._setServer(servers.first)
            }
            return
        }

        serverObserver = Current.preferences.serverUpdatedPublisher(for: server).sink { [weak self] server in
            if let server = server {
                self?._setServer(server)
            } else {
                self?._setServer(Current.preferences.getSelectedServer())
            }
        }
    }
}
