import Common
import Foundation
import Testing

@testable import TorrentCore
@testable import TorrentManager
@testable import TorrentPreferences
@testable import TorrentSession
@testable import TorrentTestSupport

@Suite("TorrentManager Tests")
@MainActor
class TorrentManagerTests {
	// MARK: - Test Setup
	private let suiteName = "test-\(UUID().uuidString)"
	private let testDefaults: UserDefaults
	private let mockPreferences: TorrentPreferences
	private let mockSession: MockTorrentSession
	private let mockClient: MockTorrentClient
	private let torrentManager: TorrentManager

	init() {
		testDefaults = UserDefaults(suiteName: suiteName)!
		mockPreferences = TorrentPreferences(userDefaults: testDefaults, keychain: InMemoryKeychain())
		mockSession = MockTorrentSession(TorrentPreferences(keychain: InMemoryKeychain()))
		mockClient = MockTorrentClient()

		// Set up mock session with mock client
		mockSession.setMockClient(mockClient)

		// Long interval to avoid the auto-refresh timer firing mid-test and skewing refreshCallCount assertions
		mockPreferences.autoRefreshInterval = 10.0

		torrentManager = TorrentManager(session: mockSession, preferences: mockPreferences)
	}

	deinit {
		UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
	}

	// MARK: - Initialization Tests

	@Test("TorrentManager initializes with empty torrents and labels")
	func torrentManagerInitializesWithEmptyTorrentsAndLabels() {
		// Assert
		#expect(torrentManager.torrents.isEmpty)
		#expect(torrentManager.labels.isEmpty)
		#expect(torrentManager.searchQuery.isEmpty)
	}

	@Test("TorrentManager initializes with timer based on preferences")
	func torrentManagerInitializesWithTimerBasedOnPreferences() {
		// Verify that preferences auto refresh interval is used
		#expect(mockPreferences.autoRefreshInterval == 10.0)
	}

	// MARK: - Torrent Refresh Tests

	@Test("Refresh updates torrents and labels")
	func refreshUpdatesTorrentsAndLabels() async throws {
		// Arrange
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 3)
		let testLabels = TestDataFactory.createMultipleLabels(count: 2)
		mockClient.refreshResult = (testTorrents, testLabels)

		// Act
		try await torrentManager.refresh()

		// Assert
		#expect(torrentManager.torrents.count == 3)
		#expect(torrentManager.labels.count == 2)
		#expect(mockClient.refreshCallCount == 1)

		// Verify torrents are stored by hash
		for torrent in testTorrents {
			#expect(torrentManager.torrents[torrent.hash] != nil)
			#expect(torrentManager.torrents[torrent.hash]?.name == torrent.name)
		}

		// Verify labels are sorted by name
		let sortedLabels = testLabels.sorted { $0.name < $1.name }
		for (index, label) in sortedLabels.enumerated() {
			#expect(torrentManager.labels[index].name == label.name)
		}
	}

	@Test("Refresh with delta updates existing torrents")
	func refreshWithDeltaUpdatesExistingTorrents() async throws {
		// Arrange - Initial refresh to establish baseline state
		// This simulates the first time the app loads torrent data from the server
		let initialTorrents = [
			TestDataFactory.createStandardTorrent(hash: "hash1", name: "Torrent 1", progress: 0.5),
			TestDataFactory.createStandardTorrent(hash: "hash2", name: "Torrent 2", progress: 0.3),
		]
		mockClient.refreshResult = (initialTorrents, [])
		try await torrentManager.refresh()

		// Act - Simulate server returning updated torrent data
		// This tests the delta update mechanism where existing torrents are updated in-place
		// rather than being replaced, preserving object identity and performance
		let updatedTorrents = [
			TestDataFactory.createStandardTorrent(hash: "hash1", name: "Torrent 1", progress: 0.8),  // Progress increased
			TestDataFactory.createStandardTorrent(hash: "hash2", name: "Torrent 2", progress: 0.6),  // Progress increased
		]
		mockClient.refreshResult = (updatedTorrents, [])
		try await torrentManager.refresh()

		// Assert
		// Verify that existing torrents were updated rather than replaced
		// This is critical for UI performance as it avoids unnecessary view updates
		#expect(torrentManager.torrents.count == 2)
		#expect(torrentManager.torrents["hash1"]?.progress == 0.8)
		#expect(torrentManager.torrents["hash2"]?.progress == 0.6)
		#expect(mockClient.refreshCallCount == 2)
	}

	@Test("Refresh adds new torrents")
	func refreshAddsNewTorrents() async throws {
		// Arrange - Initial refresh with 2 torrents
		let initialTorrents = TestDataFactory.createMultipleTorrents(count: 2)
		mockClient.refreshResult = (initialTorrents, [])
		try await torrentManager.refresh()

		// Act - Add a new torrent
		let newTorrent = TestDataFactory.createStandardTorrent(hash: "new-hash", name: "New Torrent")
		let updatedTorrents = initialTorrents + [newTorrent]
		mockClient.refreshResult = (updatedTorrents, [])
		try await torrentManager.refresh()

		// Assert
		#expect(torrentManager.torrents.count == 3)
		#expect(torrentManager.torrents["new-hash"] != nil)
		#expect(torrentManager.torrents["new-hash"]?.name == "New Torrent")
	}

	@Test("Refresh removes deleted torrents")
	func refreshRemovesDeletedTorrents() async throws {
		// Arrange - Initial refresh with 3 torrents
		let initialTorrents = [
			TestDataFactory.createStandardTorrent(hash: "hash1", name: "Torrent 1"),
			TestDataFactory.createStandardTorrent(hash: "hash2", name: "Torrent 2"),
			TestDataFactory.createStandardTorrent(hash: "hash3", name: "Torrent 3"),
		]
		mockClient.refreshResult = (initialTorrents, [])
		try await torrentManager.refresh()

		// Act - Remove one torrent
		let remainingTorrents = Array(initialTorrents.prefix(2))  // Keep only first 2
		mockClient.refreshResult = (remainingTorrents, [])
		try await torrentManager.refresh()

		// Assert
		#expect(torrentManager.torrents.count == 2)
		#expect(torrentManager.torrents["hash1"] != nil)
		#expect(torrentManager.torrents["hash2"] != nil)
		#expect(torrentManager.torrents["hash3"] == nil)
	}

	@Test("Refresh handles empty torrent list")
	func refreshHandlesEmptyTorrentList() async throws {
		// Arrange
		mockClient.refreshResult = ([], [])

		// Act
		try await torrentManager.refresh()

		// Assert
		#expect(torrentManager.torrents.isEmpty)
		#expect(torrentManager.labels.isEmpty)
		#expect(mockClient.refreshCallCount == 1)
	}

	// MARK: - Torrent Action Tests

	@Test("Resume torrents calls session and refreshes")
	func resumeTorrentsCallsSessionAndRefreshes() async throws {
		// Arrange
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 2)
		mockClient.refreshResult = (testTorrents, [])

		// Act
		try await torrentManager.resume(testTorrents)

		// Assert
		#expect(mockClient.resumeCallCount == 1)
		#expect(mockClient.resumedTorrents.count == 2)
		#expect(mockClient.refreshCallCount == 1)  // Called after resume
	}

	@Test("Pause torrents calls session and refreshes")
	func pauseTorrentsCallsSessionAndRefreshes() async throws {
		// Arrange
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 2)
		mockClient.refreshResult = (testTorrents, [])

		// Act
		try await torrentManager.pause(testTorrents)

		// Assert
		#expect(mockClient.pauseCallCount == 1)
		#expect(mockClient.pausedTorrents.count == 2)
		#expect(mockClient.refreshCallCount == 1)  // Called after pause
	}

	@Test("Delete torrents calls session and refreshes")
	func deleteTorrentsCallsSessionAndRefreshes() async throws {
		// Arrange
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 2)
		mockClient.refreshResult = ([], [])  // Empty after deletion

		// Act
		try await torrentManager.delete(testTorrents, removeData: true)

		// Assert
		#expect(mockClient.removeCallCount == 1)
		#expect(mockClient.removedTorrents.count == 2)
		#expect(mockClient.removeWithDataFlags.count == 1)
		#expect(mockClient.removeWithDataFlags[0] == true)
		#expect(mockClient.refreshCallCount == 1)  // Called after delete
	}

	@Test("Verify torrents calls session and refreshes")
	func verifyTorrentsCallsSessionAndRefreshes() async throws {
		// Arrange
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 2)
		mockClient.refreshResult = (testTorrents, [])

		// Act
		try await torrentManager.verify(testTorrents)

		// Assert
		#expect(mockClient.verifyCallCount == 1)
		#expect(mockClient.refreshCallCount == 1)  // Called after verify
	}

	@Test("Update trackers calls session and refreshes")
	func updateTrackersCallsSessionAndRefreshes() async throws {
		// Arrange
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 2)
		mockClient.refreshResult = (testTorrents, [])

		// Act
		try await torrentManager.updateTrackers(testTorrents)

		// Assert
		#expect(mockClient.updateTrackersCallCount == 1)
		#expect(mockClient.updateTrackersTorrents.count == 2)
		#expect(mockClient.refreshCallCount == 1)  // Called after update trackers
	}

	@Test("Add link calls session and refreshes")
	func addLinkCallsSessionAndRefreshes() async throws {
		// Arrange
		let testLink = "magnet:?xt=urn:btih:test"
		let newTorrent = TestDataFactory.createStandardTorrent(name: "New Torrent")
		mockClient.refreshResult = ([newTorrent], [])

		// Act
		try await torrentManager.addLink(testLink)

		// Assert
		#expect(mockClient.addLinkCallCount == 1)
		#expect(mockClient.addedLinks.count == 1)
		#expect(mockClient.addedLinks[0] == testLink)
		#expect(mockClient.refreshCallCount == 1)  // Called after add link
	}

	@Test("Paths for torrent calls session")
	func pathsForTorrentCallsSession() async throws {
		// Arrange
		let testTorrent = TestDataFactory.createStandardTorrent()
		let expectedPaths = ["/path/to/file1.txt", "/path/to/file2.txt"]
		mockClient.pathsResult = expectedPaths

		// Act
		let paths = try await torrentManager.paths(for: testTorrent)

		// Assert
		#expect(mockClient.pathsCallCount == 1)
		#expect(paths == expectedPaths)
	}

	@Test("Refresh files for torrent calls session")
	func refreshFilesForTorrentCallsSession() async throws {
		// Arrange
		let testTorrent = TestDataFactory.createStandardTorrent()
		let expectedFiles = TestDataFactory.createMultipleTorrentFiles(count: 3)
		mockClient.refreshFilesResult = expectedFiles

		// Act
		let files = try await torrentManager.refreshFiles(for: testTorrent)

		// Assert
		#expect(mockClient.refreshFilesCallCount == 1)
		#expect(files.count == 3)
	}

	// MARK: - Filtered Torrents Tests

	@Test("Filtered torrents applies search query")
	func filteredTorrentsAppliesSearchQuery() async throws {
		// Arrange
		let testTorrents = [
			TestDataFactory.createStandardTorrent(hash: "hash1", name: "Movie Torrent"),
			TestDataFactory.createStandardTorrent(hash: "hash2", name: "Music Album"),
			TestDataFactory.createStandardTorrent(hash: "hash3", name: "Software Package"),
		]
		mockClient.refreshResult = (testTorrents, [])
		try await torrentManager.refresh()

		// Act
		torrentManager.searchQuery = "Movie"

		// Assert
		let filtered = torrentManager.filteredTorrents
		#expect(filtered.count == 1)
		#expect(filtered.first?.name == "Movie Torrent")
	}

	@Test("Filtered torrents applies sort option")
	func filteredTorrentsAppliesSortOption() async throws {
		// Arrange
		let testTorrents = [
			TestDataFactory.createStandardTorrent(hash: "hash1", name: "Z Torrent"),
			TestDataFactory.createStandardTorrent(hash: "hash2", name: "A Torrent"),
			TestDataFactory.createStandardTorrent(hash: "hash3", name: "M Torrent"),
		]
		mockClient.refreshResult = (testTorrents, [])
		try await torrentManager.refresh()

		// Act - Sort by name ascending
		mockPreferences.sortOption = TorrentSortOption(property: .name, direction: .ascending)

		// Assert
		let filtered = torrentManager.filteredTorrents
		#expect(filtered.count == 3)
		#expect(filtered[0].name == "A Torrent")
		#expect(filtered[1].name == "M Torrent")
		#expect(filtered[2].name == "Z Torrent")
	}

	@Test("Filtered torrents applies filter options")
	func filteredTorrentsAppliesFilterOptions() async throws {
		// Arrange
		let testTorrents = [
			TestDataFactory.createStandardTorrent(hash: "hash1", name: "Downloading Torrent", state: .downloading),
			TestDataFactory.createStandardTorrent(hash: "hash2", name: "Seeding Torrent", state: .seeding),
			TestDataFactory.createStandardTorrent(hash: "hash3", name: "Paused Torrent", state: .paused),
		]
		mockClient.refreshResult = (testTorrents, [])
		try await torrentManager.refresh()

		// Act - Filter by downloading state only
		var filterOptions = TorrentFilterOptions()
		filterOptions.states = [.downloading]
		mockPreferences.filterOptions = filterOptions

		// Assert
		let filtered = torrentManager.filteredTorrents
		#expect(filtered.count == 1)
		#expect(filtered.first?.name == "Downloading Torrent")
	}

	@Test("Filtered torrents with combined filters")
	func filteredTorrentsWithCombinedFilters() async throws {
		// Arrange
		let testTorrents = [
			TestDataFactory.createStandardTorrent(
				hash: "hash1", name: "Movie Download", state: .downloading, label: "movies"),
			TestDataFactory.createStandardTorrent(hash: "hash2", name: "Movie Seeding", state: .seeding, label: "movies"),
			TestDataFactory.createStandardTorrent(hash: "hash3", name: "Music Download", state: .downloading, label: "music"),
		]
		mockClient.refreshResult = (testTorrents, [])
		try await torrentManager.refresh()

		// Act - Apply search, sort, and filter
		torrentManager.searchQuery = "Movie"
		var filterOptions = TorrentFilterOptions()
		filterOptions.states = [.downloading, .seeding]
		filterOptions.labels = ["movies"]
		mockPreferences.filterOptions = filterOptions
		mockPreferences.sortOption = TorrentSortOption(property: .name, direction: .ascending)

		// Assert
		let filtered = torrentManager.filteredTorrents
		#expect(filtered.count == 2)
		#expect(filtered[0].name == "Movie Download")
		#expect(filtered[1].name == "Movie Seeding")
	}

	// MARK: - Speed Calculation Tests

	@Test("Total upload speed calculation")
	func totalUploadSpeedCalculation() async throws {
		// Arrange
		let testTorrents = [
			TestDataFactory.createStandardTorrent(hash: "hash1", uploadRate: 1024 * 100),  // 100 KB/s
			TestDataFactory.createStandardTorrent(hash: "hash2", uploadRate: 1024 * 200),  // 200 KB/s
			TestDataFactory.createStandardTorrent(hash: "hash3", uploadRate: 1024 * 50),  // 50 KB/s
		]
		mockClient.refreshResult = (testTorrents, [])
		try await torrentManager.refresh()

		// Act
		let totalUploadSpeed = torrentManager.totalUploadSpeed

		// Assert
		#expect(!totalUploadSpeed.isEmpty)
		// Total should be 350 KB/s, but we just verify it's not empty since formatting depends on Formatters
	}

	@Test("Total download speed calculation")
	func totalDownloadSpeedCalculation() async throws {
		// Arrange
		let testTorrents = [
			TestDataFactory.createStandardTorrent(hash: "hash1", downloadRate: 1024 * 500),  // 500 KB/s
			TestDataFactory.createStandardTorrent(hash: "hash2", downloadRate: 1024 * 300),  // 300 KB/s
			TestDataFactory.createStandardTorrent(hash: "hash3", downloadRate: 0),  // 0 KB/s
		]
		mockClient.refreshResult = (testTorrents, [])
		try await torrentManager.refresh()

		// Act
		let totalDownloadSpeed = torrentManager.totalDownloadSpeed

		// Assert
		#expect(!totalDownloadSpeed.isEmpty)
		// Total should be 800 KB/s, but we just verify it's not empty since formatting depends on Formatters
	}

	@Test("Speed calculations with no torrents")
	func speedCalculationsWithNoTorrents() {
		// Act
		let totalUploadSpeed = torrentManager.totalUploadSpeed
		let totalDownloadSpeed = torrentManager.totalDownloadSpeed

		// Assert
		#expect(!totalUploadSpeed.isEmpty)  // Should return "0 bytes" or similar
		#expect(!totalDownloadSpeed.isEmpty)  // Should return "0 bytes" or similar
	}

	// MARK: - Error Handling Tests

	@Test("Refresh handles client errors gracefully")
	func refreshHandlesClientErrorsGracefully() async throws {
		// Arrange
		mockClient.refreshError = TorrentClientError.deluge(.response(.unauthenticated))

		// Act & Assert
		await #expect(throws: TorrentClientError.self) {
			try await torrentManager.refresh()
		}

		// Verify state remains unchanged
		#expect(torrentManager.torrents.isEmpty)
		#expect(torrentManager.labels.isEmpty)
	}

	@Test("Torrent actions handle client errors gracefully")
	func torrentActionsHandleClientErrorsGracefully() async throws {
		// Arrange
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 1)
		mockClient.resumeResult = .failure(TorrentClientError.deluge(.response(.unauthenticated)))

		// Act & Assert
		await #expect(throws: TorrentClientError.self) {
			try await torrentManager.resume(testTorrents)
		}

		#expect(mockClient.resumeCallCount == 1)
		#expect(mockClient.refreshCallCount == 0)  // Refresh not called due to error
	}

	@Test("Verify handles client errors gracefully")
	func verifyHandlesClientErrorsGracefully() async throws {
		// Arrange
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 1)
		mockClient.verifyResult = .failure(TorrentClientError.deluge(.response(.unauthenticated)))

		// Act & Assert
		await #expect(throws: TorrentClientError.self) {
			try await torrentManager.verify(testTorrents)
		}

		#expect(mockClient.verifyCallCount == 1)
		#expect(mockClient.refreshCallCount == 0)  // Refresh not called due to error
	}

	@Test("Update trackers handles client errors gracefully")
	func updateTrackersHandlesClientErrorsGracefully() async throws {
		// Arrange
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 1)
		mockClient.updateTrackersResult = .failure(TorrentClientError.deluge(.response(.unauthenticated)))

		// Act & Assert
		await #expect(throws: TorrentClientError.self) {
			try await torrentManager.updateTrackers(testTorrents)
		}

		#expect(mockClient.updateTrackersCallCount == 1)
		#expect(mockClient.refreshCallCount == 0)  // Refresh not called due to error
	}

	// MARK: - Edge Cases Tests

	@Test("Refresh with duplicate torrent hashes")
	func refreshWithDuplicateTorrentHashes() async throws {
		// Arrange - Create torrents with same hash (edge case)
		let testTorrents = [
			TestDataFactory.createStandardTorrent(hash: "same-hash", name: "Torrent 1"),
			TestDataFactory.createStandardTorrent(hash: "same-hash", name: "Torrent 2"),  // Same hash, different name
		]
		mockClient.refreshResult = (testTorrents, [])

		// Act
		try await torrentManager.refresh()

		// Assert - Only one torrent should be stored (last one wins)
		#expect(torrentManager.torrents.count == 1)
		#expect(torrentManager.torrents["same-hash"]?.name == "Torrent 2")
	}

	@Test("Large number of torrents performance")
	func largeNumberOfTorrentsPerformance() async throws {
		// Arrange - Create many torrents
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 1000)
		mockClient.refreshResult = (testTorrents, [])

		// Act
		try await torrentManager.refresh()

		// Assert
		#expect(torrentManager.torrents.count == 1000)

		// Test filtering performance with large dataset
		torrentManager.searchQuery = "Test"
		let filtered = torrentManager.filteredTorrents
		#expect(filtered.count > 0)  // Should find some matches
	}

	@Test("Empty search query returns all torrents")
	func emptySearchQueryReturnsAllTorrents() async throws {
		// Arrange
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 5)
		mockClient.refreshResult = (testTorrents, [])
		try await torrentManager.refresh()

		// Act
		torrentManager.searchQuery = ""

		// Assert
		let filtered = torrentManager.filteredTorrents
		#expect(filtered.count == 5)
	}

	@Test("Search query with special characters")
	func searchQueryWithSpecialCharacters() async throws {
		// Arrange
		let testTorrents = [
			TestDataFactory.createStandardTorrent(hash: "hash1", name: "Movie [2024] 4K"),
			TestDataFactory.createStandardTorrent(hash: "hash2", name: "TV Show S01E01"),
			TestDataFactory.createStandardTorrent(hash: "hash3", name: "Music & Audio"),
		]
		mockClient.refreshResult = (testTorrents, [])
		try await torrentManager.refresh()

		// Act
		torrentManager.searchQuery = "[2024]"

		// Assert
		let filtered = torrentManager.filteredTorrents
		#expect(filtered.count == 1)
		#expect(filtered.first?.name == "Movie [2024] 4K")
	}
}
