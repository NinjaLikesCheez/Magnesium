import Testing
import Foundation
@testable import Magnesium

@Suite("TorrentPreferences Tests")
class AppPreferencesTests {
	// MARK: - Test Setup
	private let suiteName = "test-\(UUID().uuidString)"
	private let testDefaults: UserDefaults
	private let preferences: TorrentPreferences

	init() {
		testDefaults = UserDefaults(suiteName: suiteName)!
		preferences = TorrentPreferences(userDefaults: testDefaults)
	}

	deinit {
		testDefaults.removePersistentDomain(forName: suiteName)
	}

	// MARK: - Sort and Filter Options Tests
	@Test("Sort option storage and retrieval works correctly")
	func sortOptionStorageAndRetrievalWorksCorrectly() {
		// Arrange
		let sortOption = SortOption(property: .name, direction: .ascending)

		// Act
		preferences.sortOption = sortOption

		// Assert
		#expect(preferences.sortOption.property == .name)
		#expect(preferences.sortOption.direction == .ascending)
	}

	@Test("Filter options storage and retrieval works correctly")
	func filterOptionsStorageAndRetrievalWorksCorrectly() {
		// Arrange
		var filterOptions = FilterOptions()
		filterOptions.states = [.downloading, .seeding]
		filterOptions.labels = ["linux-iso", "data"]

		// Act
		preferences.filterOptions = filterOptions

		// Assert
		#expect(preferences.filterOptions.states == [.downloading, .seeding])
		#expect(preferences.filterOptions.labels == ["linux-iso", "data"])
	}

	@Test("Auto refresh interval storage and retrieval works correctly")
	func autoRefreshIntervalStorageAndRetrievalWorksCorrectly() {
		// Arrange
		let interval: TimeInterval = 5.0

		// Act
		preferences.autoRefreshInterval = interval

		// Assert
		#expect(preferences.autoRefreshInterval == 5.0)
	}

	@Test("Automatically look for magnet links storage and retrieval works correctly")
	func automaticallyLookForMagnetLinksStorageAndRetrievalWorksCorrectly() {
		preferences.automaticallyLookForMagnetLinks = true

		// Assert
		#expect(preferences.automaticallyLookForMagnetLinks == true)
	}

	// MARK: - Preferences Reset Tests

	@Test("Reset clears all preferences")
	func resetClearsAllPreferences() throws {
		// Arrange - Set up preferences with data
		preferences.autoRefreshInterval = 10.0
		preferences.automaticallyLookForMagnetLinks = true
		preferences.sortOption = SortOption(property: .name, direction: .ascending)
		var filterOptions = FilterOptions()
		filterOptions.states = [.downloading]
		preferences.filterOptions = filterOptions

		// Act
		preferences.reset()

		// Assert - Create new preferences instance to verify persistence was cleared
		let newPreferences = TorrentPreferences(userDefaults: testDefaults)
		#expect(newPreferences.autoRefreshInterval == 2.0) // Default value
		#expect(newPreferences.automaticallyLookForMagnetLinks == false)
		#expect(newPreferences.sortOption.property == .dateAdded) // Default value
		#expect(newPreferences.filterOptions.states.isEmpty)
		#expect(newPreferences.filterOptions.labels.isEmpty)
	}

	// MARK: - Server Storage Tests (Basic functionality without keychain)

	@Test("Servers array storage and retrieval works correctly")
	func serversArrayStorageAndRetrievalWorksCorrectly() {
		// Arrange
		let data = #"{ "url": "http://localhost:8112" }"#.data(using: .utf8)!
		let keychain = #"{ "password": "test" }"#.data(using: .utf8)!
		let servers = [
			TestDataFactory.createServer(name: "Server 1", type: .deluge, data: data, keychainData: keychain),
			TestDataFactory.createServer(name: "Server 2", type: .qbittorrent, data: data, keychainData: keychain)
		]

		// Act
		preferences.servers = servers

		// Assert
		#expect(preferences.servers.count == 2)
		#expect(preferences.servers.map(\.name).sorted() == ["Server 1", "Server 2"])
	}

	@Test("Selected server ID storage and retrieval works correctly")
	func selectedServerIDStorageAndRetrievalWorksCorrectly() {
		// Act
		preferences.selectedServerID = "test-server-id"

		// Assert
		#expect(preferences.selectedServerID == "test-server-id")
	}

	@Test("Selected server ID can be set to nil")
	func selectedServerIDCanBeSetToNil() {
		// Arrange
		preferences.selectedServerID = "test-server-id"

		// Act
		preferences.selectedServerID = nil

		// Assert
		#expect(preferences.selectedServerID == nil)
	}

	// MARK: - Persistence Tests
	@Test("Preferences persist across instances")
	func preferencesPersistAcrossInstances() {
		// Arrange - Set preferences in first instance
		let preferences1 = TorrentPreferences(userDefaults: testDefaults)
		preferences1.autoRefreshInterval = 7.5
		preferences1.automaticallyLookForMagnetLinks = true
		preferences1.sortOption = SortOption(property: .uploadSpeed, direction: .descending)
		var filterOptions = FilterOptions()
		filterOptions.states = [.seeding, .paused]
		filterOptions.labels = ["test-label"]
		preferences1.filterOptions = filterOptions
		preferences1.selectedServerID = "persistent-server"

		// Act - Create new instance with same UserDefaults
		let preferences2 = TorrentPreferences(userDefaults: testDefaults)

		// Assert - Values should persist
		#expect(preferences2.autoRefreshInterval == 7.5)
		#expect(preferences2.automaticallyLookForMagnetLinks == true)
		#expect(preferences2.sortOption.property == .uploadSpeed)
		#expect(preferences2.sortOption.direction == .descending)
		#expect(preferences2.filterOptions.states == [.seeding, .paused])
		#expect(preferences2.filterOptions.labels == ["test-label"])
		#expect(preferences2.selectedServerID == "persistent-server")
	}

	// MARK: - Default Values Tests

	@Test("TorrentPreferences has correct default values")
	func appPreferencesHasCorrectDefaultValues() {
		// Assert default values
		#expect(preferences.autoRefreshInterval == 2.0)
		#expect(preferences.servers.isEmpty)
		#expect(preferences.selectedServerID == nil)
		#expect(preferences.sortOption.property == .dateAdded)
		#expect(preferences.sortOption.direction == .descending) // dateAdded prefers descending
		#expect(preferences.filterOptions.states.isEmpty)
		#expect(preferences.filterOptions.labels.isEmpty)
		#expect(preferences.automaticallyLookForMagnetLinks == false)
	}

	// MARK: - Complex Filter Options Tests

	@Test("Filter options with multiple states and labels")
	func filterOptionsWithMultipleStatesAndLabels() {
		// Arrange
		var filterOptions = FilterOptions()
		filterOptions.states = [.downloading, .seeding, .paused, .error]
		filterOptions.labels = ["linux-iso", "data", "software", "books"]

		// Act
		preferences.filterOptions = filterOptions

		// Assert
		#expect(preferences.filterOptions.states.count == 4)
		#expect(preferences.filterOptions.states.contains(.downloading))
		#expect(preferences.filterOptions.states.contains(.seeding))
		#expect(preferences.filterOptions.states.contains(.paused))
		#expect(preferences.filterOptions.states.contains(.error))

		#expect(preferences.filterOptions.labels.count == 4)
		#expect(preferences.filterOptions.labels.contains("linux-iso"))
		#expect(preferences.filterOptions.labels.contains("data"))
		#expect(preferences.filterOptions.labels.contains("software"))
		#expect(preferences.filterOptions.labels.contains("books"))
	}

	@Test("Filter options can be cleared")
	func filterOptionsCanBeCleared() {
		// Arrange - Set some filter options
		var filterOptions = FilterOptions()
		filterOptions.states = [.downloading, .seeding]
		filterOptions.labels = ["test-label"]
		preferences.filterOptions = filterOptions

		// Act - Clear filter options
		preferences.filterOptions = FilterOptions()

		// Assert
		#expect(preferences.filterOptions.states.isEmpty)
		#expect(preferences.filterOptions.labels.isEmpty)
	}

	// MARK: - Sort Option Tests

	@Test("Sort option with all properties and directions")
	func sortOptionWithAllPropertiesAndDirections() {
		let properties: [SortOption.Property] = [.dateAdded, .name, .downloadSpeed, .uploadSpeed, .progress]
		let directions: [SortOption.Direction] = [.ascending, .descending]

		for property in properties {
			for direction in directions {
				// Act
				preferences.sortOption = SortOption(property: property, direction: direction)

				// Assert
				#expect(preferences.sortOption.property == property)
				#expect(preferences.sortOption.direction == direction)
			}
		}
	}

	@Test("Sort option with opposite direction")
	func sortOptionWithOppositeDirection() {
		// Arrange
		let originalSortOption = SortOption(property: .name, direction: .ascending)
		preferences.sortOption = originalSortOption

		// Act
		preferences.sortOption = originalSortOption.withOppositeDirection()

		// Assert
		#expect(preferences.sortOption.property == .name)
		#expect(preferences.sortOption.direction == .descending)
	}

	// MARK: - Edge Cases Tests
	@Test("Filter options with empty strings in labels")
	func filterOptionsWithEmptyStringsInLabels() {
		// Arrange
		var filterOptions = FilterOptions()
		filterOptions.labels = ["", "valid-label", ""]

		// Act
		preferences.filterOptions = filterOptions

		// Assert
		#expect(preferences.filterOptions.labels.count == 2)
		#expect(preferences.filterOptions.labels.contains(""))
		#expect(preferences.filterOptions.labels.contains("valid-label"))
	}

	@Test("Filter options with special characters in labels")
	func filterOptionsWithSpecialCharactersInLabels() {
		// Arrange
		var filterOptions = FilterOptions()
		filterOptions.labels = ["🎬 movies", "tv-shows & series", "music/audio", "software.apps"]

		// Act
		preferences.filterOptions = filterOptions

		// Assert
		#expect(preferences.filterOptions.labels.count == 4)
		#expect(preferences.filterOptions.labels.contains("🎬 movies"))
		#expect(preferences.filterOptions.labels.contains("tv-shows & series"))
		#expect(preferences.filterOptions.labels.contains("music/audio"))
		#expect(preferences.filterOptions.labels.contains("software.apps"))
	}
}
