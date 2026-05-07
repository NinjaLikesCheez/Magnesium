import Deluge

struct DelugeKeychainData: Equatable, Codable {
	var password: String
	var basicAuthentication: BasicAuthentication?
}
