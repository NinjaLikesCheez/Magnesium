import Common
import Foundation
import Observation
import Sonarr
import SonarrCore

@MainActor
@Observable
public final class SonarrSession {
	public private(set) var server: SonarrServer?
	private var preferences: SonarrPreferences

	public private(set) var client: any SonarrClient = NullSonarrClient()

	public enum Error: Swift.Error {
		case missingAPIKey(server: SonarrServer)
	}

	public init(_ preferences: SonarrPreferences) {
		self.preferences = preferences
		try? _setServer(try? preferences.getServer())
	}

	public func setServer(_ server: SonarrServer) throws(Error) {
		try _setServer(server)
	}

	public func reset() {
		server = nil
		client = NullSonarrClient()
	}

	private func _setServer(_ server: SonarrServer?) throws(Error) {
		guard let server = server else {
			reset()
			return
		}

		guard let apiKey = server.apiKey else {
			reset()
			throw Error.missingAPIKey(server: server)
		}

		let sonarr = Sonarr(baseURL: server.baseURL, apiKey: apiKey)
		client = SonarrAPIClient(client: sonarr)
		self.server = server
	}
}

extension SonarrSession.Error: VisualError, Identifiable {
	public var id: Self { self }

	public var title: String {
		switch self {
		case .missingAPIKey:
			"API Key is Missing"
		}
	}

	public var subtitle: String {
		switch self {
		case let .missingAPIKey(server):
			"No API key is stored for server: \(server.name)"
		}
	}

	public var systemName: String {
		switch self {
		case .missingAPIKey:
			"key.slash"
		}
	}
}
