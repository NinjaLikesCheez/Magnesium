import Deluge

public struct DelugeKeychainData: Equatable, Codable, Sendable {
	public var password: String
	public var basicAuthentication: BasicAuthentication?
}
