import Foundation
import Testing

@testable import SonarrCore

@Suite
struct SonarrServerTests {
	@Test
	func idMatchesName() {
		let server = SonarrServer(name: "Home Server", baseURL: URL(string: "http://localhost:8989")!)
		#expect(server.id == "Home Server")
	}

	@Test
	func encodingExcludesAPIKey() throws {
		let server = SonarrServer(
			name: "Home Server",
			baseURL: URL(string: "http://localhost:8989")!,
			apiKey: "secret"
		)

		let data = try JSONEncoder().encode(server)
		let json = try #require(String(data: data, encoding: .utf8))

		#expect(!json.contains("secret"))
	}
}
