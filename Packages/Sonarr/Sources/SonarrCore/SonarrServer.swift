import Foundation

/// Connection details for a configured Sonarr instance.
///
/// Unlike `TorrentServer`, there's no backend-type enum here — Sonarr has exactly one API, so
/// every server is the same shape. The API key is kept out of `Codable` and stored separately in
/// the keychain, mirroring how `TorrentServer.keychainData` is handled.
public struct SonarrServer: Sendable, Equatable, Hashable, Identifiable {
	public var id: String { name }

	public var name: String
	public var baseURL: URL
	public var apiKey: String?

	public init(name: String, baseURL: URL, apiKey: String? = nil) {
		self.name = name
		self.baseURL = baseURL
		self.apiKey = apiKey
	}
}

extension SonarrServer: Codable {
	public enum CodingKeys: CodingKey {
		case name
		case baseURL
	}
}
