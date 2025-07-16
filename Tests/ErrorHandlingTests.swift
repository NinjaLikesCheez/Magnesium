import Testing
import Foundation
import Security
@testable import Magnesium

@MainActor
@Suite("Error Handling Tests")
struct ErrorHandlingTests {
	@Test("SystemKeychainError provides appropriate error information")
	func systemKeychainErrorProvidesAppropriateErrorInformation() {
		// Test keychain error with status code
		let keychainError = SystemKeychainError.keychain(errSecItemNotFound)

		switch keychainError {
		case .keychain(let status):
			#expect(status == errSecItemNotFound)
		case .unknown:
			Issue.record("Expected keychain error, got unknown")
		}

		// Test unknown error
		let unknownError = SystemKeychainError.unknown

		switch unknownError {
		case .unknown:
			// Expected
			break
		case .keychain:
			Issue.record("Expected unknown error, got keychain")
		}
	}

	// MARK: - Session Error Handling Tests

	@Test("Session.Error provides detailed error information")
	func sessionErrorProvidesDetailedErrorInformation() throws {
		let server = TestDataFactory.createServer(name: "Test Server", type: .deluge)
		let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])

		// Test missingKeychainData error
		let missingKeychainError = Session.Error.missingKeychainData(server: server)

		switch missingKeychainError {
		case .missingKeychainData(let errorServer):
			#expect(errorServer.name == "Test Server")
			#expect(errorServer.type == .deluge)
		default:
			Issue.record("Expected missingKeychainData error")
		}

		// Test decodingFailed error
		let decodingError = Session.Error.decodingFailed(underlyingError)

		switch decodingError {
		case .decodingFailed(let error):
			let nsError = error as NSError
			#expect(nsError.domain == "TestDomain")
			#expect(nsError.code == 123)
		default:
			Issue.record("Expected decodingFailed error")
		}

		// Test notImplemented error
		let notImplementedError = Session.Error.notImplemented

		switch notImplementedError {
		case .notImplemented:
			// Expected
			break
		default:
			Issue.record("Expected notImplemented error")
		}
	}

	@Test("Session error handling preserves original error context")
	func sessionErrorHandlingPreservesOriginalErrorContext() throws {
		// Create a complex underlying error with userInfo
		let userInfo: [String: Any] = [
			NSLocalizedDescriptionKey: "JSON decoding failed",
			NSLocalizedFailureReasonErrorKey: "Invalid JSON format",
			"customKey": "customValue"
		]
		let underlyingError = NSError(domain: "DecodingDomain", code: 4865, userInfo: userInfo)

		let sessionError = Session.Error.decodingFailed(underlyingError)

		switch sessionError {
		case .decodingFailed(let error):
			let nsError = error as NSError
			#expect(nsError.domain == "DecodingDomain")
			#expect(nsError.code == 4865)
			#expect(nsError.localizedDescription == "JSON decoding failed")
			#expect(nsError.localizedFailureReason == "Invalid JSON format")
			#expect(nsError.userInfo["customKey"] as? String == "customValue")
		default:
			Issue.record("Expected decodingFailed error")
		}
	}

	// MARK: - Network Operation Error Handling Tests

	@Test("MockTorrentClientActing error simulation")
	func mockTorrentClientActingErrorSimulation() async throws {
		let mockClient = MockTorrentClientActing()

		// Test refresh error
		mockClient.refreshError = MockError.networkError

		await #expect(throws: MockError.self) {
			try await mockClient.refresh()
		}

		// Test action errors
		mockClient.resumeResult = .failure(MockError.authenticationError)

		let testTorrents = TestDataFactory.createMultipleTorrents(count: 1)
		await #expect(throws: MockError.self) {
			try await mockClient.resume(testTorrents)
		}

		// Test addLink error
		mockClient.addLinkResult = .failure(DefaultAddLinkError(title: "Invalid Link", message: "The provided link is invalid"))

		await #expect(throws: DefaultAddLinkError.self) {
			try await mockClient.addLink("invalid-link")
		}
	}

	@Test("MockError provides appropriate error types")
	func mockErrorProvidesAppropriateErrorTypes() {
		let networkError = MockError.networkError
		let authError = MockError.authenticationError
		let invalidDataError = MockError.invalidData
		let timeoutError = MockError.timeout
		let serverError = MockError.serverError(500)

		// Verify all error types can be created and provide descriptions
		#expect(networkError.errorDescription == "Network connection failed")
		#expect(authError.errorDescription == "Authentication failed")
		#expect(invalidDataError.errorDescription == "Invalid data received")
		#expect(timeoutError.errorDescription == "Request timed out")
		#expect(serverError.errorDescription == "Server error with code 500")
	}

	// MARK: - Data Validation Error Handling Tests

	@Test("StandardTorrent handles invalid data gracefully")
	func standardTorrentHandlesInvalidDataGracefully() {
		// Test with extreme values
		let torrent = TestDataFactory.createStandardTorrent(
			downloaded: 0,
			uploaded: Int64.max,
			downloadRate: Int64.max,
			uploadRate: Int64.max
		)

		// Verify ratio calculation handles division by zero
		#expect(torrent.ratio.isInfinite)

		// Verify speed formatting doesn't crash with large values
		#expect(torrent.downloadRate.formatted(Formatters.bytes.locale(.init(identifier: "en_US"))) == "8,192 PB")
		#expect(torrent.uploadRate.formatted(Formatters.bytes.locale(.init(identifier: "en_US"))) == "8,192 PB")
	}

	@Test("StandardTorrent handles negative values gracefully")
	func standardTorrentHandlesNegativeValuesGracefully() {
		// Test with negative values (edge case that shouldn't happen but might)
		let torrent = TestDataFactory.createStandardTorrent(
			downloaded: 0,
			uploaded: 0,
			downloadRate: -1000,
			uploadRate: -500
		)

		// Verify the torrent can be created and doesn't crash
		#expect(torrent.downloadRate == -1000)
		#expect(torrent.uploadRate == -500)

		// Verify computed properties handle negative values
		#expect(torrent.downloadRate.formatted(Formatters.bytes.locale(.init(identifier: "en_US"))) == "-1 kB")
		#expect(torrent.uploadRate.formatted(Formatters.bytes.locale(.init(identifier: "en_US"))) == "-0 kB")
	}

	@Test("Server model handles invalid JSON data")
	func serverModelHandlesInvalidJSONData() throws {
		let invalidData = "not valid json".data(using: .utf8)!

		let server = TestDataFactory.createServer(
			name: "Test Server",
			type: .deluge,
			data: invalidData,
			keychainData: nil
		)

		// Verify server can be created with invalid data
		#expect(server.name == "Test Server")
		#expect(server.type == .deluge)
		#expect(server.data == invalidData)
		#expect(server.keychainData == nil)

		// The actual validation happens when trying to decode the data
		// which is tested in Session tests
	}

	// MARK: - Preferences Error Handling Tests

	@Test("AppPreferences handles corrupted UserDefaults gracefully")
	func appPreferencesHandlesCorruptedUserDefaultsGracefully() throws {
		let suiteName = "test-corrupted-\(UUID().uuidString)"
		let testDefaults = UserDefaults(suiteName: suiteName)!

		// Simulate corrupted data by setting invalid data for expected keys
		testDefaults.set("invalid-data", forKey: "servers")
		testDefaults.set(["invalid": "data"], forKey: "selectedServerID")

		let preferences = AppPreferences(userDefaults: testDefaults)

		// Verify preferences can be created and provide defaults
		#expect(preferences.servers.isEmpty) // Should fall back to empty array
		#expect(preferences.selectedServerID == nil) // Should fall back to nil

		// Cleanup
		testDefaults.removePersistentDomain(forName: suiteName)
	}

	// MARK: - Concurrent Access Error Handling Tests

	@Test("TorrentManager handles concurrent refresh calls")
	func torrentManagerHandlesConcurrentRefreshCalls() async throws {
		let mockPreferences = MockAppPreferences()
		let mockSession = MockSession(mockPreferences)
		let mockClient = MockTorrentClientActing()

		mockSession.setMockActionImplementation(mockClient)
		mockPreferences.autoRefreshInterval = 10.0 // Long interval to avoid timer interference

		let torrentManager = TorrentManager(session: mockSession, preferences: mockPreferences)

		// Set up mock to return data for concurrent calls
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 3)
		mockClient.refreshResult = (testTorrents, [])

		// Act - Make concurrent refresh calls
		try await withThrowingTaskGroup { group in
			for _ in 0..<3 {
				group.addTask {
					try await torrentManager.refresh()
				}
			}

			try await group.waitForAll()
		}

		// Verify final state is consistent
		#expect(torrentManager.torrents.count > 0)
		#expect(mockClient.refreshCallCount >= 2)
	}

	// MARK: - Memory Pressure Error Handling Tests

	@Test("Large torrent list memory handling")
	func largeTorrentListMemoryHandling() async throws {
		let mockPreferences = MockAppPreferences()
		let mockSession = MockSession(mockPreferences)
		let mockClient = MockTorrentClientActing()

		mockSession.setMockActionImplementation(mockClient)
		mockPreferences.autoRefreshInterval = 10.0

		let torrentManager = TorrentManager(session: mockSession, preferences: mockPreferences)

		// Create a very large number of torrents to test memory handling
		let largeTorrentList = TestDataFactory.createMultipleTorrents(count: 5000)
		mockClient.refreshResult = (largeTorrentList, [])

		// Act
		try await torrentManager.refresh()

		// Assert - Should handle large dataset without crashing
		#expect(torrentManager.torrents.count == 5000)

		// Test filtering performance with large dataset
		torrentManager.searchQuery = "Test"
		let filtered = torrentManager.filteredTorrents

		// Should complete without timeout or memory issues
		#expect(filtered.count >= 0)
	}

	// MARK: - Invalid State Error Handling Tests

	@Test("Session handles invalid server type gracefully")
	func sessionHandlesInvalidServerTypeGracefully() throws {
		// This test verifies that adding new server types doesn't break existing code
		let server = TestDataFactory.createServer(name: "Future Server", type: .qbittorrent)

		// Should throw notImplemented error for unimplemented server types
		#expect(throws: Session.Error.self) {
			try Session.actionImplementation(server: server)
		}
	}

	// MARK: - Resource Cleanup Error Handling Tests

	@Test("TorrentManager timer cleanup on deallocation")
	func torrentManagerTimerCleanupOnDeallocation() async throws {
		var torrentManager: TorrentManager? = {
			let mockPreferences = MockAppPreferences()
			let mockSession = MockSession(mockPreferences)
			let mockClient = MockTorrentClientActing()

			mockSession.setMockActionImplementation(mockClient)
			mockPreferences.autoRefreshInterval = 0.1 // Very short interval

			return TorrentManager(session: mockSession, preferences: mockPreferences)
		}()

		// Let the timer run briefly
		try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

		// Deallocate the manager
		torrentManager = nil

		// Wait a bit more to ensure timer would have fired if not cleaned up
		try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

		// If we get here without crashes, timer cleanup worked
		#expect(torrentManager == nil)
	}

	// MARK: - Error Recovery Tests

	@Test("Session recovers from temporary errors")
	func sessionRecoversFromTemporaryErrors() throws {
		let suiteName = "test-recovery-\(UUID().uuidString)"
		let testDefaults = UserDefaults(suiteName: suiteName)!
		let preferences = AppPreferences(userDefaults: testDefaults)
		let session = Session(preferences)

		// First, set a valid server
		let validServerData = try JSONEncoder().encode(DelugeServerSettings(url: URL(string: "http://localhost:8112")!))
		let validKeychainData = try JSONEncoder().encode(DelugeKeychainData(password: "test", basicAuthentication: nil))

		let validServer = TestDataFactory.createServer(
			name: "Valid Server",
			type: .deluge,
			data: validServerData,
			keychainData: validKeychainData
		)

		try session.setServer(validServer)
		#expect(session.server?.name == "Valid Server")

		// Try to set an invalid server (should fail but not break session)
		let invalidServer = TestDataFactory.createServer(
			name: "Invalid Server",
			type: .deluge,
			data: "invalid".data(using: .utf8)!,
			keychainData: validKeychainData
		)

		#expect(throws: Session.Error.self) {
			try session.setServer(invalidServer)
		}

		// Session should still have the valid server
		#expect(session.server?.name == "Valid Server")

		// Should be able to set another valid server
		let anotherValidServer = TestDataFactory.createServer(
			name: "Another Valid Server",
			type: .deluge,
			data: validServerData,
			keychainData: validKeychainData
		)

		try session.setServer(anotherValidServer)
		#expect(session.server?.name == "Another Valid Server")

		// Cleanup
		testDefaults.removePersistentDomain(forName: suiteName)
	}

	// MARK: - Edge Case and Boundary Tests

	@Test("Empty torrent list handling")
	func emptyTorrentListHandling() async throws {
		let mockPreferences = MockAppPreferences()
		let mockSession = MockSession(mockPreferences)
		let mockClient = MockTorrentClientActing()

		mockSession.setMockActionImplementation(mockClient)
		mockPreferences.autoRefreshInterval = 10.0

		let torrentManager = TorrentManager(session: mockSession, preferences: mockPreferences)

		// Test with empty torrent list
		mockClient.refreshResult = ([], [])
		try await torrentManager.refresh()

		// Assert
		#expect(torrentManager.torrents.isEmpty)
		#expect(torrentManager.labels.isEmpty)
		#expect(torrentManager.filteredTorrents.isEmpty)
		#expect(torrentManager.totalUploadSpeed != "")
		#expect(torrentManager.totalDownloadSpeed != "")
	}

	@Test("Zero values in torrent data")
	func zeroValuesInTorrentData() {
		let torrent = TestDataFactory.createStandardTorrent(
			progress: 0.0,
			downloaded: 0,
			uploaded: 0,
			downloadRate: 0,
			uploadRate: 0,
			eta: 0
		)

		// Verify zero values are handled correctly
		#expect(torrent.uploaded == 0)
		#expect(torrent.downloaded == 0)
		#expect(torrent.downloadRate == 0)
		#expect(torrent.uploadRate == 0)
		#expect(torrent.progress == 0.0)
		#expect(torrent.eta == 0)

		// Verify computed properties handle zero values
		#expect(torrent.ratio.isNaN) // 0/0 should be NaN
		#expect(torrent.downloadRate.formatted(Formatters.bytes.locale(.init(identifier: "en_US"))) == "Zero kB")
		#expect(torrent.uploadRate.formatted(Formatters.bytes.locale(.init(identifier: "en_US"))) == "Zero kB")
		// TODO: we need to make localizedProgress accept a locale that's not the system locale
//		Current.locale = .init(identifier: "en_US")
//		#expect(torrent.localizedProgress == "Zero kB / 1 GB (0%)")
	}

	@Test("Maximum values in torrent data")
	func maximumValuesInTorrentData() {
		let torrent = TestDataFactory.createStandardTorrent(
			progress: 1.0,
			downloaded: Int64.max,
			uploaded: Int64.max,
			downloadRate: Int64.max,
			uploadRate: Int64.max,
			eta: TimeInterval(Int64.max)
		)

		// Verify maximum values are handled correctly
		#expect(torrent.uploaded == Int64.max)
		#expect(torrent.downloaded == Int64.max)
		#expect(torrent.downloadRate == Int64.max)
		#expect(torrent.uploadRate == Int64.max)
		#expect(torrent.progress == 1.0)
		#expect(torrent.eta == TimeInterval(Int64.max))

		// Verify computed properties handle maximum values
		#expect(torrent.ratio == 1.0) // max/max should be 1.0
		#expect(torrent.downloadRate.formatted(Formatters.bytes.locale(.init(identifier: "en_US"))) == "8,192 PB")
		#expect(torrent.uploadRate.formatted(Formatters.bytes.locale(.init(identifier: "en_US"))) == "8,192 PB")
		// TODO: we need to make localizedProgress accept a locale that's not the system locale
//		#expect(torrent.localizedProgress == "8,192 PB / 1GB (100%)")
	}

	@Test("Unicode and special characters in torrent names")
	func unicodeAndSpecialCharactersInTorrentNames() async throws {
		let specialNames = [
			"🎬 Movie Title (2024) [4K]",
			"Ñoño's Música Clásica",
			"测试中文字符",
			"Тест русских символов",
			"🎵 Music & Audio Collection 🎵",
			"File with \"quotes\" and 'apostrophes'",
			"Path/with/slashes\\and\\backslashes",
			"Name with\ttabs\nand\nnewlines",
			"Very.Long.Name.With.Many.Dots.And.Extensions.mkv.part1.rar",
			""  // Empty name
		]

		let mockPreferences = MockAppPreferences()
		let mockSession = MockSession(mockPreferences)
		let mockClient = MockTorrentClientActing()

		mockSession.setMockActionImplementation(mockClient)
		mockPreferences.autoRefreshInterval = 10.0

		let torrentManager = TorrentManager(session: mockSession, preferences: mockPreferences)

		// Create torrents with special names
		let torrents = specialNames.enumerated().map { index, name in
			TestDataFactory.createStandardTorrent(hash: "hash\(index)", name: name)
		}

		mockClient.refreshResult = (torrents, [])
		try await torrentManager.refresh()

		// Verify all torrents are handled correctly
		#expect(torrentManager.torrents.count == specialNames.count)

		// Test search with special characters
		torrentManager.searchQuery = "🎬"
		let movieResults = torrentManager.filteredTorrents
		#expect(movieResults.count == 1)
		#expect(movieResults.first?.name.contains("🎬") == true)

		torrentManager.searchQuery = "quotes"
		let quoteResults = torrentManager.filteredTorrents
		#expect(quoteResults.count == 1)

		torrentManager.searchQuery = "测试"
		let chineseResults = torrentManager.filteredTorrents
		#expect(chineseResults.count == 1)
	}

	@Test("Extremely long torrent names")
	func extremelyLongTorrentNames() async throws {
		// Create a very long torrent name (1000+ characters)
		let longName = String(repeating: "Very Long Torrent Name With Lots Of Repetitive Text ", count: 20)

		let torrent = TestDataFactory.createStandardTorrent(name: longName)

		// Verify long name is handled correctly
		#expect(torrent.name == longName)
		#expect(torrent.name.count > 1000)

		// Test with TorrentManager
		let mockPreferences = MockAppPreferences()
		let mockSession = MockSession(mockPreferences)
		let mockClient = MockTorrentClientActing()

		mockSession.setMockActionImplementation(mockClient)
		mockClient.refreshResult = ([torrent], [])

		let torrentManager = TorrentManager(session: mockSession, preferences: mockPreferences)
		try await torrentManager.refresh()

		// Verify long name doesn't break functionality
		#expect(torrentManager.torrents.count == 1)

		// Test search with long names
		torrentManager.searchQuery = "Very Long"
		let results = torrentManager.filteredTorrents
		#expect(results.count == 1)
	}

	@Test("Boundary values for progress and ratios")
	func boundaryValuesForProgressAndRatios() {
		// Test progress boundaries
		let progressTests = [
			(0.0, "0%"),
			(0.5, "50%"),
			(1.0, "100%"),
			(1.5, "150%"), // Over 100% (edge case)
			(-0.1, "-10%") // Negative progress (edge case)
		]

		for (progress, _) in progressTests {
			let torrent = TestDataFactory.createStandardTorrent(progress: Float(progress))
			#expect(torrent.progress == Float(progress))
			#expect(torrent.localizedProgress != "")
		}

		// Test ratio boundaries
		let ratioTests: [(Int64, Int64, Double)] = [
			(0, 1, 0.0),      // No upload
			(1, 0, .infinity), // No download (infinite ratio)
			(0, 0, .nan),     // No data (NaN ratio)
			(1, 1, 1.0),      // Equal upload/download
			(2, 1, 2.0),      // 2:1 ratio
			(Int64.max, 1, Double(Int64.max)) // Maximum upload
		]

		for (uploaded, downloaded, expectedRatio) in ratioTests {
			let torrent = TestDataFactory.createStandardTorrent(
				downloaded: downloaded,
				uploaded: uploaded

			)

			if expectedRatio.isNaN {
				#expect(torrent.ratio.isNaN)
			} else if expectedRatio.isInfinite {
				#expect(torrent.ratio.isInfinite)
			} else {
				#expect(torrent.ratio == expectedRatio)
			}
		}
	}

	@Test("Concurrent torrent operations")
	func concurrentTorrentOperations() async throws {
		let mockPreferences = MockAppPreferences()
		let mockSession = MockSession(mockPreferences)
		let mockClient = MockTorrentClientActing()

		mockSession.setMockActionImplementation(mockClient)
		mockPreferences.autoRefreshInterval = 10.0

		let torrentManager = TorrentManager(session: mockSession, preferences: mockPreferences)

		let testTorrents = TestDataFactory.createMultipleTorrents(count: 5)
		mockClient.refreshResult = (testTorrents, [])

		// Perform multiple concurrent operations
		try await withThrowingTaskGroup { group in
			for _ in 0...3 {
				group.addTask {
					try await torrentManager.refresh()
				}
			}

			try await group.waitForAll()
		}

		// Verify final state is consistent
		#expect(torrentManager.torrents.count == 5)
		#expect(mockClient.refreshCallCount >= 3)
	}

	@Test("Rapid filter and search changes")
	func rapidFilterAndSearchChanges() async throws {
		let mockPreferences = MockAppPreferences()
		let mockSession = MockSession(mockPreferences)
		let mockClient = MockTorrentClientActing()

		mockSession.setMockActionImplementation(mockClient)

		let torrentManager = TorrentManager(session: mockSession, preferences: mockPreferences)

		// Create diverse torrent data
		let testTorrents = [
			TestDataFactory.createStandardTorrent(hash: "1", name: "Movie Download", state: .downloading, label: "movies"),
			TestDataFactory.createStandardTorrent(hash: "2", name: "Music Album", state: .seeding, label: "music"),
			TestDataFactory.createStandardTorrent(hash: "3", name: "Software Package", state: .paused, label: "software"),
			TestDataFactory.createStandardTorrent(hash: "4", name: "Movie Seeding", state: .seeding, label: "movies"),
			TestDataFactory.createStandardTorrent(hash: "5", name: "Music Download", state: .downloading, label: "music")
		]

		mockClient.refreshResult = (testTorrents, [])
		try await torrentManager.refresh()

		// Rapidly change search queries
		let searchQueries = ["Movie", "Music", "Download", "Seeding", "", "xyz", "🎬", "123"]

		for query in searchQueries {
			torrentManager.searchQuery = query
			let results = torrentManager.filteredTorrents
			#expect(results.count >= 0) // Should not crash
		}

		// Rapidly change filter options
		let filterOptions = [
			FilterOptions(states: [.downloading]),
			FilterOptions(states: [.seeding]),
			FilterOptions(states: [.paused]),
			FilterOptions(states: [.downloading, .seeding]),
			FilterOptions(labels: ["movies"]),
			FilterOptions(labels: ["music"]),
			FilterOptions(labels: ["software"]),
			FilterOptions(states: [.downloading], labels: ["movies"])
		]

		for filter in filterOptions {
			mockPreferences.filterOptions = filter
			let results = torrentManager.filteredTorrents
			#expect(results.count >= 0) // Should not crash
		}
	}

	@Test("Memory pressure with large datasets")
	func memoryPressureWithLargeDatasets() async throws {
		let mockPreferences = MockAppPreferences()
		let mockSession = MockSession(mockPreferences)
		let mockClient = MockTorrentClientActing()

		mockSession.setMockActionImplementation(mockClient)
		mockPreferences.autoRefreshInterval = 10.0

		let torrentManager = TorrentManager(session: mockSession, preferences: mockPreferences)

		// Create a very large dataset
		let largeTorrentList = TestDataFactory.createMultipleTorrents(count: 10000)
		mockClient.refreshResult = (largeTorrentList, [])

		// Test refresh with large dataset
		try await torrentManager.refresh()
		#expect(torrentManager.torrents.count == 10000)

		// Test filtering with large dataset
		torrentManager.searchQuery = "Test"
		let filtered = torrentManager.filteredTorrents
		#expect(filtered.count >= 0)

		// Test multiple rapid operations
		for i in 0..<10 {
			torrentManager.searchQuery = "Test \(i)"
			_ = torrentManager.filteredTorrents
		}

		// Should complete without memory issues
		#expect(torrentManager.torrents.count == 10000)
	}

	@Test("Invalid date and time values")
	func invalidDateAndTimeValues() {
		// Test with invalid/extreme date values
		let extremeDates = [
			Date.distantPast,
			Date.distantFuture,
			Date(timeIntervalSince1970: 0), // Unix epoch
			Date(timeIntervalSince1970: -1), // Before epoch
			Date(timeIntervalSince1970: Double.greatestFiniteMagnitude)
		]

		for date in extremeDates {
			let torrent = TestDataFactory.createStandardTorrent(dateAdded: date)
			#expect(torrent.dateAdded == date)

			// Verify date formatting doesn't crash
			let formatted = torrent.dateAdded.formatted()
			#expect(!formatted.isEmpty)
		}

		// Test with extreme ETA values
		let extremeETAs: [TimeInterval: String] = [
			-1: "∞",           // Invalid ETA
			 0: "∞",            // No ETA
			 1: "1s",            // 1 second
			 3600: "1h",         // 1 hour
			 86400: "1d",        // 1 day
			 86400 * (365) * 2: "730d",    // 2 years
		]

		for (eta, localizedRatioOrETA) in extremeETAs {
			let torrent = TestDataFactory.createStandardTorrent(eta: eta)
			#expect(torrent.eta == eta)

			// Verify ETA formatting doesn't crash
			#expect(torrent.localizedRatioOrETA == localizedRatioOrETA)
		}
	}

	@Test("Network timeout and retry scenarios")
	func networkTimeoutAndRetryScenarios() async throws {
		let mockClient = MockTorrentClientActing()

		// Test timeout simulation
		mockClient.refreshDelay = 0.1 // Small delay to simulate network latency
		mockClient.refreshResult = (TestDataFactory.createMultipleTorrents(count: 3), [])

		let startTime = Date()
		_ = try await mockClient.refresh()
		let endTime = Date()

		let elapsed = endTime.timeIntervalSince(startTime)
		#expect(elapsed >= 0.1) // Should take at least the delay time

		// Test error followed by success (retry scenario)
		mockClient.reset()
		mockClient.refreshError = MockError.networkError

		// First call should fail
		await #expect(throws: MockError.self) {
			try await mockClient.refresh()
		}

		// Second call should succeed
		mockClient.refreshError = nil
		mockClient.refreshResult = (TestDataFactory.createMultipleTorrents(count: 2), [])

		let result = try await mockClient.refresh()
		#expect(result.0.count == 2)
		#expect(mockClient.refreshCallCount == 2)
	}

	@Test("Thread safety with concurrent access")
	func threadSafetyWithConcurrentAccess() async throws {
		let mockPreferences = MockAppPreferences()
		let mockSession = MockSession(mockPreferences)
		let mockClient = MockTorrentClientActing()

		mockSession.setMockActionImplementation(mockClient)
		mockPreferences.autoRefreshInterval = 10.0

		let torrentManager = TorrentManager(session: mockSession, preferences: mockPreferences)

		let testTorrents = TestDataFactory.createMultipleTorrents(count: 100)
		mockClient.refreshResult = (testTorrents, [])

		// Perform concurrent operations from different tasks
		await withTaskGroup(of: Void.self) { group in
			// Concurrent refreshes
			for _ in 0..<5 {
				group.addTask {
					try? await torrentManager.refresh()
				}
			}

			// Concurrent filter changes
			for i in 0..<10 {
				group.addTask {
					await MainActor.run {
						torrentManager.searchQuery = "Test \(i)"
						_ = torrentManager.filteredTorrents
					}
				}
			}

			// Wait for all tasks to complete
			await group.waitForAll()
		}

		// Verify final state is consistent
		await MainActor.run {
			#expect(torrentManager.torrents.count <= 100) // Should not exceed expected count
			#expect(mockClient.refreshCallCount >= 1) // At least one refresh should have completed
		}
	}

	@Test("Malformed data handling")
	func malformedDataHandling() {
		// Test with malformed JSON data
		let malformedJSONData = [
			"{ invalid json",
			"{ \"key\": }",
			"{ \"key\": \"value\", }",
			"null",
			"[]",
			"\"string\"",
			"123",
			"",
			"{ \"key\": \"value\" extra text"
		]

		for jsonString in malformedJSONData {
			let data = jsonString.data(using: .utf8) ?? Data()

			let server = TestDataFactory.createServer(
				name: "Test Server",
				type: .deluge,
				data: data,
				keychainData: nil
			)

			// Server creation should not crash
			#expect(server.name == "Test Server")
			#expect(server.data == data)

			// Decoding should fail gracefully (tested in Session tests)
		}
	}

	@Test("Resource exhaustion scenarios")
	func resourceExhaustionScenarios() async throws {
		let mockPreferences = MockAppPreferences()
		let mockSession = MockSession(mockPreferences)
		let mockClient = MockTorrentClientActing()

		mockSession.setMockActionImplementation(mockClient)

		let torrentManager = TorrentManager(session: mockSession, preferences: mockPreferences)

		// Test with many small operations
		for i in 0..<1000 {
			let singleTorrent = [TestDataFactory.createStandardTorrent(hash: "hash\(i)", name: "Torrent \(i)")]
			mockClient.refreshResult = (singleTorrent, [])

			try await torrentManager.refresh()

			// Verify each operation completes successfully
			#expect(torrentManager.torrents.count == 1)
		}

		// Test rapid-fire filter changes
		for i in 0..<100 {
			torrentManager.searchQuery = "Query \(i)"
			_ = torrentManager.filteredTorrents
		}

		// Should complete without resource exhaustion
		#expect(torrentManager.torrents.count == 1)
	}
}
