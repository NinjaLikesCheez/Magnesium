import Deluge

public struct DelugeKeychainData: Equatable, Codable, Sendable {
	public let password: String
	public let basicAuthentication: BasicAuthentication?

	public init(password: String, basicAuthentication: BasicAuthentication? = nil) {
		self.password = password
		self.basicAuthentication = basicAuthentication
	}
}
