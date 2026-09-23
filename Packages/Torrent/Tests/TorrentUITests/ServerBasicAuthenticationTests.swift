import Deluge
import Testing

@testable import TorrentUI

@Suite("ServerBasicAuthentication Tests")
struct ServerBasicAuthenticationTests {
	@Test("init treats nil values as empty strings")
	func initDefaultsToEmptyStrings() {
		let authentication = ServerBasicAuthentication()

		#expect(authentication.username.isEmpty)
		#expect(authentication.password.isEmpty)
	}

	@Test("toAPIClient returns nil unless both username and password are set")
	func toAPIClientRequiresBothFields() {
		#expect(ServerBasicAuthentication().toAPIClient() == nil)
		#expect(ServerBasicAuthentication(username: "user").toAPIClient() == nil)
		#expect(ServerBasicAuthentication(password: "pass").toAPIClient() == nil)
	}

	@Test("toAPIClient carries over both fields when set")
	func toAPIClientCarriesOverFields() {
		let authentication = ServerBasicAuthentication(username: "user", password: "pass")

		#expect(authentication.toAPIClient() == BasicAuthentication(username: "user", password: "pass"))
	}

	@Test("toServerBasicAuthentication carries over both fields")
	func toServerBasicAuthenticationCarriesOverFields() {
		let authentication = BasicAuthentication(username: "user", password: "pass").toServerBasicAuthentication()

		#expect(authentication.username == "user")
		#expect(authentication.password == "pass")
	}
}
