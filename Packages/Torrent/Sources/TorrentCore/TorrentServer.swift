import Foundation

public struct TorrentServer: Sendable, Equatable, Hashable, Identifiable {
	public var id: String { name }

	public var name: String
	public var type: TorrentServerType
	public var data: Data
	public var keychainData: Data?

	public init(name: String, type: TorrentServerType, data: Data, keychainData: Data?) {
		self.name = name
		self.type = type
		self.data = data
		self.keychainData = keychainData
	}
}

extension TorrentServer: Codable {
	public enum CodingKeys: CodingKey {
		case name
		case type
		case data
	}
}
