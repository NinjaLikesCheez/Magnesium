import Foundation

struct Server: Codable, Equatable {
    enum CodingKeys: CodingKey {
        case id
        case name
        case type
        case data
    }

    // swiftlint:disable:next type_name
    typealias ID = String
    private(set) var id: ID = UUID().uuidString
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
