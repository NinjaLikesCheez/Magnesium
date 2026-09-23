import Testing

@testable import TorrentUI

@Suite("QBittorrentSettings Tests")
@MainActor
struct QBittorrentSettingsTests {
	@Test("default init starts with empty fields")
	func defaultInitIsEmpty() {
		let settings = QBittorrentSettings()

		#expect(settings.name.isEmpty)
		#expect(settings.address.isEmpty)
		#expect(settings.username.isEmpty)
		#expect(settings.password.isEmpty)
		#expect(settings.basicAuthentication.toAPIClient() == nil)
	}

	@Test("memberwise init stores all fields")
	func memberwiseInitStoresFields() {
		let settings = QBittorrentSettings(
			name: "qBittorrent",
			address: "http://localhost:8080",
			username: "admin",
			password: "adminadmin",
			basicAuthentication: .init(username: "user", password: "pass")
		)

		#expect(settings.name == "qBittorrent")
		#expect(settings.address == "http://localhost:8080")
		#expect(settings.username == "admin")
		#expect(settings.password == "adminadmin")
		#expect(settings.basicAuthentication.username == "user")
		#expect(settings.basicAuthentication.password == "pass")
	}
}
