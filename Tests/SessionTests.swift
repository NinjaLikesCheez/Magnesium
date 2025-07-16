import Testing
import Foundation
@testable import Magnesium

@Suite("Session Tests")
class SessionTests {

	// MARK: - Test Setup
	private let suiteName: String
	private let testDefaults: UserDefaults
	private let preferences: AppPreferences
	private let session: Session

	init() {
		suiteName = "test-\(UUID().uuidString)"
		testDefaults = UserDefaults(suiteName: suiteName)!
		preferences = AppPreferences(userDefaults: testDefaults)
		session = .init(preferences)
	}

	deinit {
		testDefaults.removePersistentDomain(forName: suiteName)
	}

	// MARK: - Initialization Tests

	@Test("Session initializes with no server when preferences are empty")
	func sessionInitializesWithNoServerWhenPreferencesAreEmpty() {
		// Assert
		#expect(session.server == nil)
		#expect(session.actionImplementation is NullTorrentActionImplementation)
	}

	@Test("Session initializes with selected server from preferences")
	func sessionInitializesWithSelectedServerFromPreferences() throws {
		// Arrange - Set up server in preferences first
		let preferences = AppPreferences()
		let server = TestDataFactory.createServer(name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)
		try preferences.addOrUpdate(server: server)
		preferences.selectedServerID = server.id

		// Act - Create new session
		let session = Session(preferences)

		// Assert
		#expect(session.server?.name == "Test Server")
	}

	// MARK: - Server Setting Tests

	private let serverSettingsData = #"{ "url": "http://localhost:8112" }"#.data(using: .utf8)!
	private let keychainData = #"{ "password": "test" }"#.data(using: .utf8)!

	@Test("Set server updates server property")
	func setServerUpdatesServerProperty() throws {
		// Arrange
		let server = TestDataFactory.createServer(name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)

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
		let server = TestDataFactory.createServer(name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)

		// Act
		try session.setServer(server)

		// Assert
		#expect(preferences.selectedServerID == server.id)
	}

	@Test("Set server with nil clears server")
	func setServerWithNilClearsServer() throws {
		// Arrange - First set a server
		let server = TestDataFactory.createServer(name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)
		try session.setServer(server)

		// Act
		session.reset()

		// Assert
		#expect(session.server == nil)
		#expect(session.actionImplementation is NullTorrentActionImplementation)
	}

	// MARK: - Action Implementation Creation Tests

	@Test("Action implementation creation for Deluge server with valid data")
	func actionImplementationCreationForDelugeServerWithValidData() throws {
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
		let actionImplementation = try Session.actionImplementation(server: server)

		// Assert
		#expect(!(actionImplementation is NullTorrentActionImplementation))
		// The actual type would be DelugeActionImplementation, but we can't easily test that without more setup
	}

	@Test("Action implementation creation throws error for missing keychain data")
	func actionImplementationCreationThrowsErrorForMissingKeychainData() throws {
		// Arrange
		let serverSettings = DelugeServerSettings(url: URL(string: "http://localhost:58846")!)
		let encoder = JSONEncoder()
		let serverData = try encoder.encode(serverSettings)

		let server = TestDataFactory.createServer(
			name: "Deluge Server",
			type: .deluge,
			data: serverData,
			keychainData: nil // Missing keychain data
		)

		// Act & Assert
		let error = #expect(throws: Session.Error.self) {
			try Session.actionImplementation(server: server)
		}

		if case .missingKeychainData(let errorServer) = error {
			#expect(errorServer.name == "Deluge Server")
		} else {
			Issue.record("Expected missingKeychainData error")
		}
	}

	@Test("Action implementation creation throws error for invalid server data")
	func actionImplementationCreationThrowsErrorForInvalidServerData() throws {
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
		let error = #expect(throws: Session.Error.self) {
			try Session.actionImplementation(server: server)
		}

		if case .decodingFailed = error {
			// Expected error type
		} else {
			Issue.record("Expected decodingFailed error")
		}
	}

	@Test("Action implementation creation throws error for invalid keychain data")
	func actionImplementationCreationThrowsErrorForInvalidKeychainData() throws {
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
		let error = #expect(throws: Session.Error.self) {
			try Session.actionImplementation(server: server)
		}
		if case .decodingFailed = error {
			// Expected error type
		} else {
			Issue.record("Expected decodingFailed error")
		}
	}

	@Test("Action implementation creation throws not implemented for QBittorrent")
	func actionImplementationCreationThrowsNotImplementedForQBittorrent() throws {
		// Arrange
		let server = TestDataFactory.createServer(
			name: "QBittorrent Server",
			type: .qbittorrent,
			data: Data(),
			keychainData: Data()
		)

		// Act & Assert
		let error = #expect(throws: Session.Error.self) {
			try Session.actionImplementation(server: server)
		}
		if case .notImplemented = error {
			// Expected error type
		} else {
			Issue.record("Expected notImplemented error")
		}
	}

	// MARK: - Server Switching Tests

	@Test("Server switching updates action implementation")
	func serverSwitchingUpdatesActionImplementation() throws {
		// Arrange
		let server1 = TestDataFactory.createServer(name: "Server 1", type: .deluge, data: serverSettingsData, keychainData: keychainData)
		let server2 = TestDataFactory.createServer(name: "Server 2", type: .deluge, data: serverSettingsData, keychainData: keychainData)

		// Act - Set first server
		try session.setServer(server1)
		let firstImplementation = session.actionImplementation

		// Act - Switch to second server
		try session.setServer(server2)
		let secondImplementation = session.actionImplementation

		// Assert
		#expect(session.server?.name == "Server 2")
		#expect(preferences.selectedServerID == server2.id)
		// The action implementations should be different instances
		#expect(!(firstImplementation === secondImplementation))
	}

	@Test("Server switching from valid server to nil resets to null implementation")
	func serverSwitchingFromValidServerToNilResetsToNullImplementation() throws {
		// Arrange
		let server = TestDataFactory.createServer(name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)
		try session.setServer(server)

		// Act
		session.reset()

		// Assert
		#expect(session.server == nil)
		#expect(session.actionImplementation is NullTorrentActionImplementation)
	}

	// MARK: - Reset Functionality Tests

	@Test("Reset clears server and resets action implementation")
	func resetClearsServerAndResetsActionImplementation() throws {
		// Arrange
		let server = TestDataFactory.createServer(name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)
		try session.setServer(server)

		// Act
		session.reset()

		// Assert
		#expect(session.server == nil)
		#expect(session.actionImplementation is NullTorrentActionImplementation)
	}

	@Test("Reset works when no server is set")
	func resetWorksWhenNoServerIsSet() {
		// Act - Reset when no server is set
		session.reset()

		// Assert
		#expect(session.server == nil)
		#expect(session.actionImplementation is NullTorrentActionImplementation)
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
		let error = #expect(throws: Session.Error.self) {
			try session.setServer(server)
		}

		if case .missingKeychainData(let errorServer) = error {
			#expect(errorServer.name == "Deluge Server")
		} else {
			Issue.record("Expected missingKeychainData error")
		}

		// Verify session state remains unchanged
		#expect(session.server == nil)
		#expect(session.actionImplementation is NullTorrentActionImplementation)
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
		let error = #expect(throws: Session.Error.self) {
			try session.setServer(server)
		}

		if case .decodingFailed = error {
			// Expected error type
		} else {
			Issue.record("Expected decodingFailed error")
		}

		// Verify session state remains unchanged
		#expect(session.server == nil)
		#expect(session.actionImplementation is NullTorrentActionImplementation)
	}

	// MARK: - Edge Cases Tests

	@Test("Multiple consecutive server sets work correctly")
	func multipleConsecutiveServerSetsWorkCorrectly() throws {
		// Arrange
		let servers = [
			TestDataFactory.createServer(name: "Server 1", type: .deluge, data: serverSettingsData, keychainData: keychainData),
			TestDataFactory.createServer(name: "Server 2", type: .deluge, data: serverSettingsData, keychainData: keychainData),
			TestDataFactory.createServer(name: "Server 3", type: .deluge, data: serverSettingsData, keychainData: keychainData)
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
		let server = TestDataFactory.createServer(name: "Test Server", type: .deluge, data: serverSettingsData, keychainData: keychainData)

		// Act - Set same server multiple times
		try session.setServer(server)
		let firstImplementation = session.actionImplementation

		try session.setServer(server)
		let secondImplementation = session.actionImplementation

		try session.setServer(server)
		let thirdImplementation = session.actionImplementation

		// Assert
		#expect(session.server?.name == "Test Server")
		#expect(preferences.selectedServerID == server.id)

		// Each call should create a new action implementation
		#expect(!(firstImplementation === secondImplementation))
		#expect(!(secondImplementation === thirdImplementation))
	}

	// MARK: - NullTorrentActionImplementation Tests

	@Test("NullTorrentActionImplementation throws errors for all methods")
	func nullTorrentActionImplementationThrowsErrorsForAllMethods() async {
		let nullImplementation = NullTorrentActionImplementation()
		let testTorrent = TestDataFactory.createStandardTorrent()
		let testLabel = TestDataFactory.createStandardLabel()

		// Test all methods throw NotReadyError
		await #expect(throws: NullTorrentActionImplementation.NotReadyError.self) {
			try await nullImplementation.refresh()
		}

		await #expect(throws: NullTorrentActionImplementation.NotReadyError.self) {
			try await nullImplementation.refreshFiles(testTorrent)
		}

		await #expect(throws: DefaultAddLinkError.self) {
			try await nullImplementation.addLink("http://example.com")
		}

		await #expect(throws: NullTorrentActionImplementation.NotReadyError.self) {
			try await nullImplementation.paths(testTorrent)
		}

		await #expect(throws: NullTorrentActionImplementation.NotReadyError.self) {
			try await nullImplementation.pause([testTorrent])
		}

		await #expect(throws: NullTorrentActionImplementation.NotReadyError.self) {
			try await nullImplementation.resume([testTorrent])
		}

		await #expect(throws: NullTorrentActionImplementation.NotReadyError.self) {
			try await nullImplementation.remove([testTorrent], false)
		}

		await #expect(throws: NullTorrentActionImplementation.NotReadyError.self) {
			try await nullImplementation.verify([testTorrent])
		}

		await #expect(throws: NullTorrentActionImplementation.NotReadyError.self) {
			try await nullImplementation.setLabel(testLabel, [testTorrent])
		}

		await #expect(throws: NullTorrentActionImplementation.NotReadyError.self) {
			try await nullImplementation.updateTrackers([testTorrent])
		}

		await #expect(throws: NullTorrentActionImplementation.NotReadyError.self) {
			try await nullImplementation.moveDownloadFolder("/test/path", [testTorrent])
		}
	}

	@Test("DefaultAddLinkError has correct properties")
	func defaultAddLinkErrorHasCorrectProperties() async {
		let nullImplementation = NullTorrentActionImplementation()

		let error = await #expect(throws: DefaultAddLinkError.self) {
			try await nullImplementation.addLink("http://example.com")
		}

		guard let error else {
			Issue.record("Expected addLink to throw DefaultAddLinkError")
			return
		}

		#expect(error.title == "Not Ready")
		#expect(error.message == "Torrent actions are not ready.")
	}
}

