import Common
import Foundation
import Testing

@testable import TorrentCore
@testable import TorrentPreferences
@testable import TorrentSession

@Suite("TorrentSession Tests")
@MainActor
class TorrentSessionTests {

	// MARK: - Test Setup
	private let suiteName: String
	private let testDefaults: UserDefaults
	private let preferences: TorrentPreferences
	private let session: TorrentSession

	init() {
		suiteName = "test-\(UUID().uuidString)"
		testDefaults = UserDefaults(suiteName: suiteName)!
		preferences = TorrentPreferences(userDefaults: testDefaults, keychain: InMemoryKeychain())
		session = .init(preferences)
	}

	deinit {
		UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
	}

	// MARK: - Initialization Tests

	@Test("TorrentSession initializes with no server when preferences are empty")
	func sessionInitializesWithNoServerWhenPreferencesAreEmpty() {
		// Assert
		#expect(session.server == nil)
		#expect(session.client is NullTorrentClient)
	}

	@Test("TorrentSession initializes with selected server from preferences")
	func sessionInitializesWithSelectedServerFromPreferences() throws {
		// Arrange - Set up server in preferences first
		let preferences = TorrentPreferences(keychain: InMemoryKeychain())
		let server = TestDataFactory.createServer(
			name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)
		try preferences.addOrUpdate(server: server)
		preferences.selectedServerID = server.id

		// Act - Create new session
		let session = TorrentSession(preferences)

		// Assert
		#expect(session.server?.name == "Test Server")
	}

	// MARK: - Server Setting Tests

	private let serverSettingsData = #"{ "url": "http://localhost:8112" }"#.data(using: .utf8)!
	private let keychainData = #"{ "password": "test" }"#.data(using: .utf8)!

	@Test("Set server updates server property")
	func setServerUpdatesServerProperty() throws {
		// Arrange
		let server = TestDataFactory.createServer(
			name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)

		// Act
		try session.setServer(server)

		// Assert
		#expect(session.server?.name == "Test Server")
		#expect(session.server?.type == .deluge)
		#expect(session.server?.data == serverSettingsData)
		#expect(session.server?.keychainData == keychainData)
	}

	@Test("Set server updates selected server ID in preferences")
	func setServerUpdatesSelectedServerIDInPreferences() throws {
		// Arrange
		let server = TestDataFactory.createServer(
			name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)

		// Act
		try session.setServer(server)

		// Assert
		#expect(preferences.selectedServerID == server.id)
	}

	@Test("Set server with nil clears server")
	func setServerWithNilClearsServer() throws {
		// Arrange - First set a server
		let server = TestDataFactory.createServer(
			name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)
		try session.setServer(server)

		// Act
		session.reset()

		// Assert
		#expect(session.server == nil)
		#expect(session.client is NullTorrentClient)
	}

	// MARK: - Action Implementation Creation Tests

	@Test("Client creation for Deluge server with valid data")
	func clientCreationForDelugeServerWithValidData() throws {
		// Arrange
		let serverSettings = DelugeServerSettings(url: URL(string: "http://localhost:58846")!)
		let keychainData = DelugeKeychainData(password: "test-password", basicAuthentication: nil)

		let encoder = JSONEncoder()
		let serverData = try encoder.encode(serverSettings)
		let keychainDataEncoded = try encoder.encode(keychainData)

		let server = TestDataFactory.createServer(
			name: "Deluge Server",
			type: .deluge,
			data: serverData,
			keychainData: keychainDataEncoded
		)

		// Act
		try session.setServer(server)

		// Assert
		#expect(!(session.client is NullTorrentClient))
	}

	@Test("Client creation throws error for missing keychain data")
	func clientCreationThrowsErrorForMissingKeychainData() throws {
		// Arrange
		let serverSettings = DelugeServerSettings(url: URL(string: "http://localhost:58846")!)
		let encoder = JSONEncoder()
		let serverData = try encoder.encode(serverSettings)

		let server = TestDataFactory.createServer(
			name: "Deluge Server",
			type: .deluge,
			data: serverData,
			keychainData: nil  // Missing keychain data
		)

		// Act & Assert
		let error = #expect(throws: TorrentSession.Error.self) {
			try session.setServer(server)
		}

		if case .missingKeychainData(let errorServer) = error {
			#expect(errorServer.name == "Deluge Server")
		} else {
			Issue.record("Expected missingKeychainData error")
		}
	}

	@Test("Client creation throws error for invalid server data")
	func clientCreationThrowsErrorForInvalidServerData() throws {
		// Arrange
		let invalidServerData = "invalid json".data(using: .utf8)!
		let keychainData = DelugeKeychainData(password: "test-password", basicAuthentication: nil)

		let encoder = JSONEncoder()
		let keychainDataEncoded = try encoder.encode(keychainData)

		let server = TestDataFactory.createServer(
			name: "Deluge Server",
			type: .deluge,
			data: invalidServerData,
			keychainData: keychainDataEncoded
		)

		// Act & Assert
		let error = #expect(throws: TorrentSession.Error.self) {
			try session.setServer(server)
		}

		if case .decodingFailed = error {
			// Expected error type
		} else {
			Issue.record("Expected decodingFailed error")
		}
	}

	@Test("Client creation throws error for invalid keychain data")
	func clientCreationThrowsErrorForInvalidKeychainData() throws {
		// Arrange
		let serverSettings = DelugeServerSettings(url: URL(string: "http://localhost:58846")!)
		let encoder = JSONEncoder()
		let serverData = try encoder.encode(serverSettings)
		let invalidKeychainData = "invalid json".data(using: .utf8)!

		let server = TestDataFactory.createServer(
			name: "Deluge Server",
			type: .deluge,
			data: serverData,
			keychainData: invalidKeychainData
		)

		// Act & Assert
		let error = #expect(throws: TorrentSession.Error.self) {
			try session.setServer(server)
		}
		if case .decodingFailed = error {
			// Expected error type
		} else {
			Issue.record("Expected decodingFailed error")
		}
	}

	@Test("Client creation throws not implemented for QBittorrent")
	func clientCreationThrowsNotImplementedForQBittorrent() throws {
		// Arrange
		let server = TestDataFactory.createServer(
			name: "QBittorrent Server",
			type: .qbittorrent,
			data: Data(),
			keychainData: Data()
		)

		// Act & Assert
		let error = #expect(throws: TorrentSession.Error.self) {
			try session.setServer(server)
		}
		if case .notImplemented = error {
			// Expected error type
		} else {
			Issue.record("Expected notImplemented error")
		}
	}

	// MARK: - Server Switching Tests

	@Test("Server switching updates client")
	func serverSwitchingUpdatesClient() throws {
		// Arrange
		let server1 = TestDataFactory.createServer(
			name: "Server 1", type: .deluge, data: serverSettingsData, keychainData: keychainData)
		let server2 = TestDataFactory.createServer(
			name: "Server 2", type: .deluge, data: serverSettingsData, keychainData: keychainData)

		// Act - Set first server
		try session.setServer(server1)
		let firstClient = session.client

		// Act - Switch to second server
		try session.setServer(server2)
		let secondClient = session.client

		// Assert
		#expect(session.server?.name == "Server 2")
		#expect(preferences.selectedServerID == server2.id)
		// The clients should be different instances
		#expect(!(firstClient === secondClient))
	}

	@Test("Server switching from valid server to nil resets to null implementation")
	func serverSwitchingFromValidServerToNilResetsToNullImplementation() throws {
		// Arrange
		let server = TestDataFactory.createServer(
			name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)
		try session.setServer(server)

		// Act
		session.reset()

		// Assert
		#expect(session.server == nil)
		#expect(session.client is NullTorrentClient)
	}

	// MARK: - Reset Functionality Tests

	@Test("Reset clears server and resets client")
	func resetClearsServerAndResetsClient() throws {
		// Arrange
		let server = TestDataFactory.createServer(
			name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)
		try session.setServer(server)

		// Act
		session.reset()

		// Assert
		#expect(session.server == nil)
		#expect(session.client is NullTorrentClient)
	}

	@Test("Reset works when no server is set")
	func resetWorksWhenNoServerIsSet() {
		// Act - Reset when no server is set
		session.reset()

		// Assert
		#expect(session.server == nil)
		#expect(session.client is NullTorrentClient)
	}

	// MARK: - Error Handling Tests

	@Test("Set server handles missing keychain data gracefully")
	func setServerHandlesMissingKeychainDataGracefully() throws {
		// Arrange
		let server = TestDataFactory.createServer(
			name: "Deluge Server",
			type: .deluge,
			data: serverSettingsData,
			keychainData: nil
		)

		// Act & Assert
		let error = #expect(throws: TorrentSession.Error.self) {
			try session.setServer(server)
		}

		if case .missingKeychainData(let errorServer) = error {
			#expect(errorServer.name == "Deluge Server")
		} else {
			Issue.record("Expected missingKeychainData error")
		}

		// Verify session state remains unchanged
		#expect(session.server == nil)
		#expect(session.client is NullTorrentClient)
	}

	@Test("Set server handles decoding failures gracefully")
	func setServerHandlesDecodingFailuresGracefully() throws {
		// Arrange
		let invalidServerData = #"invalid json"#.data(using: .utf8)!

		let server = TestDataFactory.createServer(
			name: "Deluge Server",
			type: .deluge,
			data: invalidServerData,
			keychainData: keychainData
		)

		// Act & Assert
		let error = #expect(throws: TorrentSession.Error.self) {
			try session.setServer(server)
		}

		if case .decodingFailed = error {
			// Expected error type
		} else {
			Issue.record("Expected decodingFailed error")
		}

		// Verify session state remains unchanged
		#expect(session.server == nil)
		#expect(session.client is NullTorrentClient)
	}

	// MARK: - Edge Cases Tests

	@Test("Multiple consecutive server sets work correctly")
	func multipleConsecutiveServerSetsWorkCorrectly() throws {
		// Arrange
		let servers = [
			TestDataFactory.createServer(
				name: "Server 1", type: .deluge, data: serverSettingsData, keychainData: keychainData),
			TestDataFactory.createServer(
				name: "Server 2", type: .deluge, data: serverSettingsData, keychainData: keychainData),
			TestDataFactory.createServer(
				name: "Server 3", type: .deluge, data: serverSettingsData, keychainData: keychainData),
		]

		// Act & Assert
		for server in servers {
			try session.setServer(server)
			#expect(session.server?.name == server.name)
			#expect(preferences.selectedServerID == server.id)
		}

		// Final state should be the last server
		#expect(session.server?.name == "Server 3")
	}

	@Test("Set server with same server multiple times")
	func setServerWithSameServerMultipleTimes() throws {
		// Arrange
		let server = TestDataFactory.createServer(
			name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)

		// Act - Set same server multiple times
		try session.setServer(server)
		let firstClient = session.client

		try session.setServer(server)
		let secondClient = session.client

		try session.setServer(server)
		let thirdClient = session.client

		// Assert
		#expect(session.server?.name == "Test Server")
		#expect(preferences.selectedServerID == server.id)

		// Each call should create a new client
		#expect(!(firstClient === secondClient))
		#expect(!(secondClient === thirdClient))
	}

	// MARK: - NullTorrentClient Tests

	@Test("NullTorrentClient throws errors for all methods")
	func nullTorrentClientThrowsErrorsForAllMethods() async {
		let nullClient = NullTorrentClient()
		let testTorrent = TestDataFactory.createStandardTorrent()
		let testLabel = TestDataFactory.createStandardLabel()

		func expectNullImplementation(_ operation: () async throws -> Void) async {
			do {
				try await operation()
				Issue.record("Expected TorrentClientError.nullImplementation to be thrown")
			} catch let error as TorrentClientError {
				guard case .nullImplementation = error else {
					Issue.record("Expected TorrentClientError.nullImplementation, got \(error)")
					return
				}
			} catch {
				Issue.record("Expected TorrentClientError.nullImplementation, got \(error)")
			}
		}

		// Test all methods throw nullImplementation
		await expectNullImplementation { _ = try await nullClient.refresh() }
		await expectNullImplementation { _ = try await nullClient.refreshFiles(testTorrent) }
		await expectNullImplementation { try await nullClient.addLink("http://example.com") }
		await expectNullImplementation { _ = try await nullClient.paths(testTorrent) }
		await expectNullImplementation { try await nullClient.pause([testTorrent]) }
		await expectNullImplementation { try await nullClient.resume([testTorrent]) }
		await expectNullImplementation { try await nullClient.remove([testTorrent], false) }
		await expectNullImplementation { try await nullClient.verify([testTorrent]) }
		await expectNullImplementation { try await nullClient.setLabel(testLabel, [testTorrent]) }
		await expectNullImplementation { try await nullClient.updateTrackers([testTorrent]) }
		await expectNullImplementation { try await nullClient.moveDownloadFolder("/test/path", [testTorrent]) }
	}
}
