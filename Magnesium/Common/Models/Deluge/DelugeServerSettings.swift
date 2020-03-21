import Foundation

struct DelugeServerSettings {
    var url: URL
}

extension DelugeServerSettings: Codable {}
extension DelugeServerSettings: Equatable {}
