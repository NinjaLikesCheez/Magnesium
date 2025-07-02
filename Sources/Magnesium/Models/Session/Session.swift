import Combine
import Foundation
import Observation

@Observable
final class Session {
	private(set) var server: Server?
	private var serverObserver: AnyCancellable?

	private(set) var actionImplementation: any TorrentClientActing = NullTorrentActionImplementation()

	enum Error: Swift.Error {
		case missingKeychainData(server: Server)
		case decodingFailed(Swift.Error)
		case notImplemented
	}

	init() {
		try? _setServer(try? Current.preferences.getSelectedServer())

		withObservationTracking(of: Current.preferences.selectedServerID) { _ in
			try? self._setServer(try? Current.preferences.getSelectedServer())
		}
	}

	func setServer(_ server: Server) throws(Error) {
		try _setServer(server)
	}

	func reset() {
		server = nil
	}

	private func _setServer(_ server: Server?) throws(Error) {
		self.server = server
		actionImplementation = NullTorrentActionImplementation()

		if let server = server {
			actionImplementation = try Session.actionImplementation(server: server)
			Current.preferences.selectedServerID = server.id
		}
	}
}

extension Session {
	static func actionImplementation(server: Server) throws(Error) -> any TorrentClientActing {
		switch server.type {
		case .deluge:
			let decoder = JSONDecoder()
			guard let keychainData = server.keychainData else {
				throw Error.missingKeychainData(server: server)
			}

			do {
				let settings = try decoder.decode(DelugeServerSettings.self, from: server.data)
				let keychain = try decoder.decode(DelugeKeychainData.self, from: keychainData)
				let client = Current.deluge(settings.url, keychain.password, keychain.basicAuthentication)
				return DelugeActionImplementation(session: .init(client: client))
			} catch {
				throw Error.decodingFailed(error)
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
			throw Error.notImplemented
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
