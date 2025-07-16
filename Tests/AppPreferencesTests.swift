import Testing
import Foundation
@testable import Magnesium

@Suite("AppPreferences Tests")
struct AppPreferencesTests {
    
    // MARK: - Test Setup
	private let suiteName = "test-\(UUID().uuidString)"

    private func createTestEnvironment() -> (AppPreferences, UserDefaults) {
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let preferences = AppPreferences(userDefaults: testDefaults)
        
        return (preferences, testDefaults)
    }
    
    private func tearDown(testDefaults: UserDefaults) {
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    // MARK: - Sort and Filter Options Tests
    
    @Test("Sort option storage and retrieval works correctly")
    func sortOptionStorageAndRetrievalWorksCorrectly() {
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
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
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
        // Arrange
        var filterOptions = FilterOptions()
        filterOptions.states = [.downloading, .seeding]
        filterOptions.labels = ["movies", "tv-shows"]
        
        // Act
        preferences.filterOptions = filterOptions
        
        // Assert
        #expect(preferences.filterOptions.states == [.downloading, .seeding])
        #expect(preferences.filterOptions.labels == ["movies", "tv-shows"])
    }
    
    @Test("Auto refresh interval storage and retrieval works correctly")
    func autoRefreshIntervalStorageAndRetrievalWorksCorrectly() {
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
        // Arrange
        let interval: TimeInterval = 5.0
        
        // Act
        preferences.autoRefreshInterval = interval
        
        // Assert
        #expect(preferences.autoRefreshInterval == 5.0)
    }
    
    @Test("Automatically look for magnet links storage and retrieval works correctly")
    func automaticallyLookForMagnetLinksStorageAndRetrievalWorksCorrectly() {
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
        // Act
        preferences.automaticallyLookForMagnetLinks = true
        
        // Assert
        #expect(preferences.automaticallyLookForMagnetLinks == true)
    }
    
    // MARK: - Preferences Reset Tests
    
    @Test("Reset clears all preferences")
    func resetClearsAllPreferences() throws {
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
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
        let newPreferences = AppPreferences(userDefaults: testDefaults)
        #expect(newPreferences.autoRefreshInterval == 2.0) // Default value
        #expect(newPreferences.automaticallyLookForMagnetLinks == false)
        #expect(newPreferences.sortOption.property == .dateAdded) // Default value
        #expect(newPreferences.filterOptions.states.isEmpty)
        #expect(newPreferences.filterOptions.labels.isEmpty)
    }
    
    // MARK: - Server Storage Tests (Basic functionality without keychain)
    
    @Test("Servers array storage and retrieval works correctly")
    func serversArrayStorageAndRetrievalWorksCorrectly() {
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
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
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
        // Act
        preferences.selectedServerID = "test-server-id"
        
        // Assert
        #expect(preferences.selectedServerID == "test-server-id")
    }
    
    @Test("Selected server ID can be set to nil")
    func selectedServerIDCanBeSetToNil() {
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
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
        let testDefaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        defer { testDefaults.removePersistentDomain(forName: suiteName) }
        
        // Arrange - Set preferences in first instance
        let preferences1 = AppPreferences(userDefaults: testDefaults)
        preferences1.autoRefreshInterval = 7.5
        preferences1.automaticallyLookForMagnetLinks = true
        preferences1.sortOption = SortOption(property: .uploadSpeed, direction: .descending)
        var filterOptions = FilterOptions()
        filterOptions.states = [.seeding, .paused]
        filterOptions.labels = ["test-label"]
        preferences1.filterOptions = filterOptions
        preferences1.selectedServerID = "persistent-server"
        
        // Act - Create new instance with same UserDefaults
        let preferences2 = AppPreferences(userDefaults: testDefaults)
        
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
    
    @Test("AppPreferences has correct default values")
    func appPreferencesHasCorrectDefaultValues() {
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
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
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
        // Arrange
        var filterOptions = FilterOptions()
        filterOptions.states = [.downloading, .seeding, .paused, .error]
        filterOptions.labels = ["movies", "tv-shows", "music", "software"]
        
        // Act
        preferences.filterOptions = filterOptions
        
        // Assert
        #expect(preferences.filterOptions.states.count == 4)
        #expect(preferences.filterOptions.states.contains(.downloading))
        #expect(preferences.filterOptions.states.contains(.seeding))
        #expect(preferences.filterOptions.states.contains(.paused))
        #expect(preferences.filterOptions.states.contains(.error))
        
        #expect(preferences.filterOptions.labels.count == 4)
        #expect(preferences.filterOptions.labels.contains("movies"))
        #expect(preferences.filterOptions.labels.contains("tv-shows"))
        #expect(preferences.filterOptions.labels.contains("music"))
        #expect(preferences.filterOptions.labels.contains("software"))
    }
    
    @Test("Filter options can be cleared")
    func filterOptionsCanBeCleared() {
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
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
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
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
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
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
    
    @Test("Auto refresh interval with extreme values")
    func autoRefreshIntervalWithExtremeValues() {
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
        // Test very small interval
        preferences.autoRefreshInterval = 0.1
        #expect(preferences.autoRefreshInterval == 0.1)
        
        // Test very large interval
        preferences.autoRefreshInterval = 3600.0 // 1 hour
        #expect(preferences.autoRefreshInterval == 3600.0)
        
        // Test zero interval
        preferences.autoRefreshInterval = 0.0
        #expect(preferences.autoRefreshInterval == 0.0)
    }
    
    @Test("Filter options with empty strings in labels")
    func filterOptionsWithEmptyStringsInLabels() {
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
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
        let (preferences, testDefaults) = createTestEnvironment()
        defer { tearDown(testDefaults: testDefaults) }
        
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
