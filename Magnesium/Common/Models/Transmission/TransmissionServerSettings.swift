import Foundation

struct TransmissionServerSettings {
    var url: URL
    var username: String?
}

extension TransmissionServerSettings: Codable {}
extension TransmissionServerSettings: Equatable {}
