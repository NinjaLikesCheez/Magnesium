import Common
import Deluge
import Foundation
import Observation
import TorrentPreferences

@Observable
public final class TorrentSession: TorrentSessionProtocol {
	public private(set) var server: TorrentServer?
	private var preferences: TorrentPreferences

	public private(set) var client: any TorrentClient = NullTorrentClient()

	public enum Error: Swift.Error {
		case missingKeychainData(server: TorrentServer)
		case decodingFailed(String)
		case notImplemented
	}

	public init(_ preferences: TorrentPreferences) {
		self.preferences = preferences
		try? _setServer(try? preferences.getSelectedServer())

		// TODO: fix this... sendable nonsense
		let selectedServerID = Observations {
			preferences.selectedServerID
		}

		Task {
			for await _ in selectedServerID {
				try? self._setServer(try preferences.getSelectedServer())
			}
		}
	}

	public func setServer(_ server: TorrentServer) throws(Error) {
		try _setServer(server)
	}

	public func reset() {
		server = nil
		client = NullTorrentClient()
		preferences.selectedServerID = nil
	}

	private func _setServer(_ server: TorrentServer?) throws(Error) {
		if let server = server {
			do {
				client = try TorrentSession.client(server: server)
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

extension TorrentSession {
	static func client(server: TorrentServer) throws(Error) -> any TorrentClient {
		switch server.type {
		case .deluge:
			let decoder = JSONDecoder()
			guard let keychainData = server.keychainData else {
				let error = Error.missingKeychainData(server: server)
				ErrorReporting.capture(error, feature: "keychain", operation: "missing_data")
				throw error
			}

			do {
				let settings = try decoder.decode(DelugeServerSettings.self, from: server.data)
				let keychain = try decoder.decode(DelugeKeychainData.self, from: keychainData)
				let client = Deluge(
					baseURL: settings.url,
					password: keychain.password,
					basicAuthentication: keychain.basicAuthentication
				)

				return DelugeClient(session: .init(client: client))
			} catch let error as DecodingError {
				ErrorReporting.capture(error, feature: "decoding", operation: "server_settings")
				throw Error.decodingFailed(error.localizedDescription)
			} catch {
				fatalError("Unhandled Error: \(error)")
			}
		case .qbittorrent:
			let error = Error.notImplemented
			ErrorReporting.capture(error, feature: "session", operation: "qbittorrent_client")
			throw error
		}
	}
}

extension TorrentSession.Error: VisualError, Identifiable {
	public var id: Self { self }

	public var title: String {
		switch self {
		case .missingKeychainData:
			"Keychain Data is Missing"
		case .decodingFailed:
			"Decoding Failed"
		case .notImplemented:
			"Not Implemented"
		}
	}

	public var subtitle: String {
		switch self {
		case let .missingKeychainData(server):
			"Keychain data is missing for server: \(server.name)"
		case let .decodingFailed(error):
			"Couldn't decode server settings: \(error)"
		case .notImplemented:
			"This feature is not implemented yet"
		}
	}

	public var systemName: String {
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
