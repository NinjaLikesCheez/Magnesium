import Combine
import Foundation
import Observation

@Observable
final class Session {
	private(set) var server: Server!
	private var serverObserver: AnyCancellable?

	private(set) var actionImplementation: TorrentActionImplementation!

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
			actionImplementation = Session.actionImplementation(server: server)
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

extension Session {
	static func actionImplementation(server: Server) -> TorrentActionImplementation {
		switch server.type {
		case .deluge:
			let decoder = JSONDecoder()
			guard let settings = try? decoder.decode(DelugeServerSettings.self, from: server.data),
				let keychainData = server.keychainData,
				let keychain = try? decoder.decode(DelugeKeychainData.self, from: keychainData)
			else {
				fatalError("Failed to decode Deluge settings")
			}
			let client = Current.deluge(settings.url, keychain.password, keychain.basicAuthentication)
			return .deluge(.init(client: client))
		// case .transmission:
		// 	let decoder = JSONDecoder()
		// 	guard let settings = try? decoder.decode(TransmissionServerSettings.self, from: server.data),
		// 		let keychainData = server.keychainData,
		// 		let keychain = try? decoder.decode(TransmissionKeychainData.self, from: keychainData)
		// 	else {
		// 		return nil
		// 	}
		// 	let client = Current.transmission(settings.url, settings.username, keychain.password)
		// 	return .transmission(.init(client: client))
		case .qbittorrent:
			fatalError("Not implemented")
		// let decoder = JSONDecoder()
		// guard let settings = try? decoder.decode(QBittorrentServerSettings.self, from: server.data),
		// 	let keychainData = server.keychainData,
		// 	let keychain = try? decoder.decode(QBittorrentKeychainData.self, from: keychainData)
		// else {
		// 	return nil
		// }
		// let client = Current.qbittorrent(settings.url, settings.username, keychain.password, keychain.basicAuthentication)
		// return .qbittorrent(.init(client: client))
		}
	}
}
