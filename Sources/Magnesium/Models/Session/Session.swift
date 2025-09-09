import Combine
import Foundation
import Observation

@Observable
final class Session: SessionProtocol {
	private(set) var server: Server?
	private var preferences: Preferences
	private var serverObserver: AnyCancellable?

	private(set) var actionImplementation: any TorrentClientActing = NullTorrentActionImplementation()

	enum Error: Swift.Error {
		case missingKeychainData(server: Server)
		case decodingFailed(String)
		case notImplemented
	}

	init(_ preferences: Preferences) {
		self.preferences = preferences
		try? _setServer(try? preferences.getSelectedServer())

		withObservationTracking(of: preferences.selectedServerID) { _ in
			try? self._setServer(try? preferences.getSelectedServer())
		}
	}

	func setServer(_ server: Server) throws(Error) {
		try _setServer(server)
	}

	func reset() {
		server = nil
		actionImplementation = NullTorrentActionImplementation()
		preferences.selectedServerID = nil
	}

	private func _setServer(_ server: Server?) throws(Error) {
		if let server = server {
			do {
				actionImplementation = try Session.actionImplementation(server: server)
				self.server = server
				preferences.selectedServerID = server.id
			} catch {
				reset()
				throw error
			}
		} else {
			reset()
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
			} catch let error as DecodingError {
				throw Error.decodingFailed(error.localizedDescription)
			} catch {
				fatalError("Unhandled Error: \(error)")
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

extension Session.Error: VisualError {
	var title: String {
		switch self {
		case .missingKeychainData:
			"Keychain Data is Missing"
		case .decodingFailed:
			"Decoding Failed"
		case .notImplemented:
			"Not Implemented"
		}
	}

	var subtitle: String {
		switch self {
		case let .missingKeychainData(server):
			"Keychain data is missing for server: \(server.name)"
		case let .decodingFailed(error):
			"Couldn't decode server settings: \(error)"
		case .notImplemented:
			"This feature is not implemented yet"
		}
	}

	var systemName: String {
		switch self {
		case .missingKeychainData:
			"lock.trianglebadge.exclamationmark.fill"
		case .decodingFailed:
			"gear.badge.xmark"
		case .notImplemented:
			"questionmark.diamond"
		}
	}
}
