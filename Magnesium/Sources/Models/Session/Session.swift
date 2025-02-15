import Combine
import Observation

@Observable
final class Session {
	private(set) var server: Server?
	private var serverObserver: AnyCancellable?

	init() {
		_setServer(try? Current.preferences.getSelectedServer())
	}

	func setServer(_ server: Server) {
		_setServer(server)
	}

	private func _setServer(_ server: Server?) {
		self.server = server
		setupServerObserver()
		if let server = server {
			Current.preferences[.selectedServerID] = server.id
		}
	}

	private func setupServerObserver() {
		guard let server = server else {
			serverObserver = Current.preferences.updatePublisher(for: .servers).sink { [weak self] servers in
				self?._setServer(servers.first)
			}
			return
		}

		serverObserver = Current.preferences.serverUpdatedPublisher(for: server).sink { [weak self] server in
			if let server = server {
				self?._setServer(server)
			} else {
				self?._setServer(try? Current.preferences.getSelectedServer())
			}
		}
	}
}
