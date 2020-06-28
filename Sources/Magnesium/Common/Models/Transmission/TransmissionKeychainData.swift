struct TransmissionKeychainData {
    var password: String?
}

extension TransmissionKeychainData: Codable {}
extension TransmissionKeychainData: Equatable {}
