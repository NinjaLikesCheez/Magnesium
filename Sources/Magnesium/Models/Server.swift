import Foundation

public struct Server: Equatable, Hashable {
	public var id: String { name }
	var name: String
	var type: ServerType
	var data: Data
	var keychainData: Data?

	init(name: String, type: ServerType, data: Data, keychainData: Data?) {
		self.name = name
		self.type = type
		self.data = data
		self.keychainData = keychainData
	}
}

extension Server: Codable {
	enum CodingKeys: CodingKey {
		case name
		case type
		case data
	}
}

extension Server: Identifiable {}
