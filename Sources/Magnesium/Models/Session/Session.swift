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

	func reset() {
		server = nil
	}

	private func _setServer(_ server: Server?) {
		self.server = server
		if let server = server {
			Current.preferences.selectedServerID = server.id
			actionImplementation = Session.actionImplementation(server: server)
		}
	}

}

extension Session {
	static func actionImplementation(server: Server) -> TorrentActionImplementation {
		switch server.type {
		case .deluge:
			let decoder = JSONDecoder()
			do {
				guard let keychainData = server.keychainData else {
					fatalError("Failed to fetch keychain data for server: \(server)")
				}

				let settings = try decoder.decode(DelugeServerSettings.self, from: server.data)
				let keychain = try decoder.decode(DelugeKeychainData.self, from: keychainData)

				let client = Current.deluge(settings.url, keychain.password, keychain.basicAuthentication)
				return .deluge(.init(client: client))
			} catch {
				fatalError("Failed to decode Deluge settings: \(error.localizedDescription)")
			}

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
