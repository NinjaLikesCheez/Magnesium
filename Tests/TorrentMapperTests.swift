import Testing
import Foundation
@testable import Magnesium

@Suite("TorrentMapper Tests")
struct TorrentMapperTests {
	// MARK: - Filtering Tests

	@Suite("Filtering Tests")
	struct FilteringTests {
		
		@Test("Filter torrents by single state")
		func filterTorrentsBySingleState() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Torrent1", state: .downloading),
				TestDataFactory.createStandardTorrent(name: "Torrent2", state: .seeding),
				TestDataFactory.createStandardTorrent(name: "Torrent3", state: .paused),
				TestDataFactory.createStandardTorrent(name: "Torrent4", state: .downloading)
			]
			let filterOptions = FilterOptions(states: [.downloading], labels: [])
			
			// Act
			let result = TorrentMapper.filter(torrents, using: filterOptions, query: "")
			
			// Assert
			#expect(result.count == 2)
			#expect(result.allSatisfy { $0.state == .downloading })
			#expect(result.contains { $0.name == "Torrent1" })
			#expect(result.contains { $0.name == "Torrent4" })
		}
		
		@Test("Filter torrents by multiple states")
		func filterTorrentsByMultipleStates() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Torrent1", state: .downloading),
				TestDataFactory.createStandardTorrent(name: "Torrent2", state: .seeding),
				TestDataFactory.createStandardTorrent(name: "Torrent3", state: .paused),
				TestDataFactory.createStandardTorrent(name: "Torrent4", state: .error),
				TestDataFactory.createStandardTorrent(name: "Torrent5", state: .downloading)
			]
			let filterOptions = FilterOptions(states: [.downloading, .seeding], labels: [])
			
			// Act
			let result = TorrentMapper.filter(torrents, using: filterOptions, query: "")
			
			// Assert
			#expect(result.count == 3)
			#expect(result.allSatisfy { $0.state == .downloading || $0.state == .seeding })
			#expect(result.contains { $0.name == "Torrent1" })
			#expect(result.contains { $0.name == "Torrent2" })
			#expect(result.contains { $0.name == "Torrent5" })
		}
		
		@Test("Filter torrents by single label")
		func filterTorrentsBySingleLabel() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Torrent1", label: "Movies"),
				TestDataFactory.createStandardTorrent(name: "Torrent2", label: "TV Shows"),
				TestDataFactory.createStandardTorrent(name: "Torrent3", label: "Music"),
				TestDataFactory.createStandardTorrent(name: "Torrent4", label: "Movies")
			]
			let filterOptions = FilterOptions(states: [], labels: ["Movies"])
			
			// Act
			let result = TorrentMapper.filter(torrents, using: filterOptions, query: "")
			
			// Assert
			#expect(result.count == 2)
			#expect(result.allSatisfy { $0.label == "Movies" })
			#expect(result.contains { $0.name == "Torrent1" })
			#expect(result.contains { $0.name == "Torrent4" })
		}
		
		@Test("Filter torrents by multiple labels")
		func filterTorrentsByMultipleLabels() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Torrent1", label: "Movies"),
				TestDataFactory.createStandardTorrent(name: "Torrent2", label: "TV Shows"),
				TestDataFactory.createStandardTorrent(name: "Torrent3", label: "Music"),
				TestDataFactory.createStandardTorrent(name: "Torrent4", label: "Games"),
				TestDataFactory.createStandardTorrent(name: "Torrent5", label: "Movies")
			]
			let filterOptions = FilterOptions(states: [], labels: ["Movies", "Music"])
			
			// Act
			let result = TorrentMapper.filter(torrents, using: filterOptions, query: "")
			
			// Assert
			#expect(result.count == 3)
			#expect(result.allSatisfy { $0.label == "Movies" || $0.label == "Music" })
			#expect(result.contains { $0.name == "Torrent1" })
			#expect(result.contains { $0.name == "Torrent3" })
			#expect(result.contains { $0.name == "Torrent5" })
		}
		
		@Test("Search functionality with basic query")
		func searchFunctionalityWithBasicQuery() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Ubuntu Linux Distribution"),
				TestDataFactory.createStandardTorrent(name: "Windows Software Package"),
				TestDataFactory.createStandardTorrent(name: "Linux Mint ISO"),
				TestDataFactory.createStandardTorrent(name: "macOS Installer")
			]
			let filterOptions = FilterOptions()
			
			// Act
			let result = TorrentMapper.filter(torrents, using: filterOptions, query: "linux")
			
			// Assert
			#expect(result.count == 2)
			#expect(result.contains { $0.name == "Ubuntu Linux Distribution" })
			#expect(result.contains { $0.name == "Linux Mint ISO" })
		}
		
		@Test("Search functionality with special characters")
		func searchFunctionalityWithSpecialCharacters() {
			// Arrange
			// Test torrent names with common special characters found in real torrent names:
			// - Dots (.) used as space separators
			// - Underscores (_) used as space separators  
			// - Hyphens (-) used as separators
			// - Parentheses and brackets for additional info
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Movie.Title.2023.1080p.BluRay"),
				TestDataFactory.createStandardTorrent(name: "TV_Show_S01E01_720p"),
				TestDataFactory.createStandardTorrent(name: "Album-Artist-2023-MP3"),
				TestDataFactory.createStandardTorrent(name: "Game Title (2023) [Repack]")
			]
			let filterOptions = FilterOptions()
			
			// Act
			// Search should normalize special characters and match across word boundaries
			let result1 = TorrentMapper.filter(torrents, using: filterOptions, query: "movie title")
			let result2 = TorrentMapper.filter(torrents, using: filterOptions, query: "tv show")
			let result3 = TorrentMapper.filter(torrents, using: filterOptions, query: "game title")
			
			// Assert
			// Verify that search finds matches despite special character differences
			#expect(result1.count == 1)
			#expect(result1.first?.name == "Movie.Title.2023.1080p.BluRay")
			
			#expect(result2.count == 1)
			#expect(result2.first?.name == "TV_Show_S01E01_720p")
			
			#expect(result3.count == 1)
			#expect(result3.first?.name == "Game Title (2023) [Repack]")
		}
		
		@Test("Search functionality with partial matches")
		func searchFunctionalityWithPartialMatches() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "The Matrix Reloaded"),
				TestDataFactory.createStandardTorrent(name: "Matrix Revolutions"),
				TestDataFactory.createStandardTorrent(name: "Enter the Matrix Game"),
				TestDataFactory.createStandardTorrent(name: "Unrelated Content")
			]
			let filterOptions = FilterOptions()
			
			// Act
			let result = TorrentMapper.filter(torrents, using: filterOptions, query: "matrix")
			
			// Assert
			#expect(result.count == 3)
			#expect(result.contains { $0.name == "The Matrix Reloaded" })
			#expect(result.contains { $0.name == "Matrix Revolutions" })
			#expect(result.contains { $0.name == "Enter the Matrix Game" })
		}
		
		@Test("Combined filtering operations - state and label")
		func combinedFilteringStateAndLabel() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Movie1", state: .downloading, label: "Movies"),
				TestDataFactory.createStandardTorrent(name: "Movie2", state: .seeding, label: "Movies"),
				TestDataFactory.createStandardTorrent(name: "Show1", state: .downloading, label: "TV Shows"),
				TestDataFactory.createStandardTorrent(name: "Movie3", state: .paused, label: "Movies")
			]
			let filterOptions = FilterOptions(states: [.downloading], labels: ["Movies"])
			
			// Act
			let result = TorrentMapper.filter(torrents, using: filterOptions, query: "")
			
			// Assert
			#expect(result.count == 1)
			#expect(result.first?.name == "Movie1")
			#expect(result.first?.state == .downloading)
			#expect(result.first?.label == "Movies")
		}
		
		@Test("Combined filtering operations - state, label, and search")
		func combinedFilteringStateLabelandSearch() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Action Movie 2023", state: .downloading, label: "Movies"),
				TestDataFactory.createStandardTorrent(name: "Comedy Movie 2023", state: .seeding, label: "Movies"),
				TestDataFactory.createStandardTorrent(name: "Action TV Show", state: .downloading, label: "TV Shows"),
				TestDataFactory.createStandardTorrent(name: "Drama Movie 2023", state: .downloading, label: "Movies")
			]
			let filterOptions = FilterOptions(states: [.downloading], labels: ["Movies"])
			
			// Act
			let result = TorrentMapper.filter(torrents, using: filterOptions, query: "action")
			
			// Assert
			#expect(result.count == 1)
			#expect(result.first?.name == "Action Movie 2023")
		}
		
		@Test("Filter with empty torrent list")
		func filterWithEmptyTorrentList() {
			// Arrange
			let torrents: [StandardTorrent] = []
			let filterOptions = FilterOptions(states: [.downloading], labels: ["Movies"])
			
			// Act
			let result = TorrentMapper.filter(torrents, using: filterOptions, query: "test")
			
			// Assert
			#expect(result.isEmpty)
		}
		
		@Test("Filter with empty filters returns all torrents")
		func filterWithEmptyFiltersReturnsAllTorrents() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Torrent1"),
				TestDataFactory.createStandardTorrent(name: "Torrent2"),
				TestDataFactory.createStandardTorrent(name: "Torrent3")
			]
			let filterOptions = FilterOptions()
			
			// Act
			let result = TorrentMapper.filter(torrents, using: filterOptions, query: "")
			
			// Assert
			#expect(result.count == 3)
			#expect(result == torrents)
		}
		
		@Test("Search with whitespace-only query returns all torrents")
		func searchWithWhitespaceOnlyQueryReturnsAllTorrents() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Torrent1"),
				TestDataFactory.createStandardTorrent(name: "Torrent2")
			]
			let filterOptions = FilterOptions()
			
			// Act
			let result = TorrentMapper.filter(torrents, using: filterOptions, query: "   ")
			
			// Assert
			#expect(result.count == 2)
			#expect(result == torrents)
		}
		
		@Test("Search with no matches returns empty list")
		func searchWithNoMatchesReturnsEmptyList() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Ubuntu Linux"),
				TestDataFactory.createStandardTorrent(name: "Windows Software")
			]
			let filterOptions = FilterOptions()
			
			// Act
			let result = TorrentMapper.filter(torrents, using: filterOptions, query: "nonexistent")
			
			// Assert
			#expect(result.isEmpty)
		}
	}   
	// MARK: - Sorting Tests
	
	@Suite("Sorting Tests")
	struct SortingTests {
		
		@Test("Sort by name ascending with case-insensitive ordering")
		func sortByNameAscendingCaseInsensitive() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "zebra"),
				TestDataFactory.createStandardTorrent(name: "Apple"),
				TestDataFactory.createStandardTorrent(name: "banana"),
				TestDataFactory.createStandardTorrent(name: "Cherry")
			]
			let sortOption = SortOption(property: .name, direction: .ascending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 4)
			#expect(result[0].name == "Apple")
			#expect(result[1].name == "banana")
			#expect(result[2].name == "Cherry")
			#expect(result[3].name == "zebra")
		}
		
		@Test("Sort by name descending with case-insensitive ordering")
		func sortByNameDescendingCaseInsensitive() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Apple"),
				TestDataFactory.createStandardTorrent(name: "zebra"),
				TestDataFactory.createStandardTorrent(name: "banana"),
				TestDataFactory.createStandardTorrent(name: "Cherry")
			]
			let sortOption = SortOption(property: .name, direction: .descending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 4)
			#expect(result[0].name == "zebra")
			#expect(result[1].name == "Cherry")
			#expect(result[2].name == "banana")
			#expect(result[3].name == "Apple")
		}
		
		@Test("Sort by name with numeric ordering")
		func sortByNameWithNumericOrdering() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "File10.txt"),
				TestDataFactory.createStandardTorrent(name: "File2.txt"),
				TestDataFactory.createStandardTorrent(name: "File1.txt"),
				TestDataFactory.createStandardTorrent(name: "File20.txt")
			]
			let sortOption = SortOption(property: .name, direction: .ascending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 4)
			#expect(result[0].name == "File1.txt")
			#expect(result[1].name == "File2.txt")
			#expect(result[2].name == "File10.txt")
			#expect(result[3].name == "File20.txt")
		}
		
		@Test("Sort by dateAdded ascending")
		func sortByDateAddedAscending() {
			// Arrange
			let date1 = Date(timeIntervalSince1970: 1000)
			let date2 = Date(timeIntervalSince1970: 2000)
			let date3 = Date(timeIntervalSince1970: 3000)
			
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Torrent3", dateAdded: date3),
				TestDataFactory.createStandardTorrent(name: "Torrent1", dateAdded: date1),
				TestDataFactory.createStandardTorrent(name: "Torrent2", dateAdded: date2)
			]
			let sortOption = SortOption(property: .dateAdded, direction: .ascending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 3)
			#expect(result[0].name == "Torrent1")
			#expect(result[1].name == "Torrent2")
			#expect(result[2].name == "Torrent3")
		}
		
		@Test("Sort by dateAdded descending")
		func sortByDateAddedDescending() {
			// Arrange
			let date1 = Date(timeIntervalSince1970: 1000)
			let date2 = Date(timeIntervalSince1970: 2000)
			let date3 = Date(timeIntervalSince1970: 3000)
			
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Torrent1", dateAdded: date1),
				TestDataFactory.createStandardTorrent(name: "Torrent3", dateAdded: date3),
				TestDataFactory.createStandardTorrent(name: "Torrent2", dateAdded: date2)
			]
			let sortOption = SortOption(property: .dateAdded, direction: .descending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 3)
			#expect(result[0].name == "Torrent3")
			#expect(result[1].name == "Torrent2")
			#expect(result[2].name == "Torrent1")
		}
		
		@Test("Sort by downloadSpeed ascending")
		func sortByDownloadSpeedAscending() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Fast", downloadRate: 1000),
				TestDataFactory.createStandardTorrent(name: "Slow", downloadRate: 100),
				TestDataFactory.createStandardTorrent(name: "Medium", downloadRate: 500)
			]
			let sortOption = SortOption(property: .downloadSpeed, direction: .ascending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 3)
			#expect(result[0].name == "Slow")
			#expect(result[1].name == "Medium")
			#expect(result[2].name == "Fast")
		}
		
		@Test("Sort by downloadSpeed descending")
		func sortByDownloadSpeedDescending() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Slow", downloadRate: 100),
				TestDataFactory.createStandardTorrent(name: "Fast", downloadRate: 1000),
				TestDataFactory.createStandardTorrent(name: "Medium", downloadRate: 500)
			]
			let sortOption = SortOption(property: .downloadSpeed, direction: .descending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 3)
			#expect(result[0].name == "Fast")
			#expect(result[1].name == "Medium")
			#expect(result[2].name == "Slow")
		}
		
		@Test("Sort by uploadSpeed ascending")
		func sortByUploadSpeedAscending() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Fast", uploadRate: 800),
				TestDataFactory.createStandardTorrent(name: "Slow", uploadRate: 50),
				TestDataFactory.createStandardTorrent(name: "Medium", uploadRate: 300)
			]
			let sortOption = SortOption(property: .uploadSpeed, direction: .ascending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 3)
			#expect(result[0].name == "Slow")
			#expect(result[1].name == "Medium")
			#expect(result[2].name == "Fast")
		}
		
		@Test("Sort by uploadSpeed descending")
		func sortByUploadSpeedDescending() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Medium", uploadRate: 300),
				TestDataFactory.createStandardTorrent(name: "Slow", uploadRate: 50),
				TestDataFactory.createStandardTorrent(name: "Fast", uploadRate: 800)
			]
			let sortOption = SortOption(property: .uploadSpeed, direction: .descending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 3)
			#expect(result[0].name == "Fast")
			#expect(result[1].name == "Medium")
			#expect(result[2].name == "Slow")
		}
		
		@Test("Sort by progress ascending")
		func sortByProgressAscending() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Complete", progress: 1.0),
				TestDataFactory.createStandardTorrent(name: "Starting", progress: 0.1),
				TestDataFactory.createStandardTorrent(name: "Half", progress: 0.5)
			]
			let sortOption = SortOption(property: .progress, direction: .ascending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 3)
			#expect(result[0].name == "Starting")
			#expect(result[1].name == "Half")
			#expect(result[2].name == "Complete")
		}
		
		@Test("Sort by progress descending")
		func sortByProgressDescending() {
			// Arrange
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Starting", progress: 0.1),
				TestDataFactory.createStandardTorrent(name: "Complete", progress: 1.0),
				TestDataFactory.createStandardTorrent(name: "Half", progress: 0.5)
			]
			let sortOption = SortOption(property: .progress, direction: .descending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 3)
			#expect(result[0].name == "Complete")
			#expect(result[1].name == "Half")
			#expect(result[2].name == "Starting")
		}
		
		@Test("Sort stability with secondary name sorting")
		func sortStabilityWithSecondaryNameSorting() {
			// Arrange
			// Create torrents with identical primary sort values (progress) to test secondary sorting
			// This tests the sort stability requirement - when primary values are equal,
			// the system should fall back to secondary sorting by name
			let torrents = [
				TestDataFactory.createStandardTorrent(name: "Zebra", progress: 0.5),
				TestDataFactory.createStandardTorrent(name: "Apple", progress: 0.5),
				TestDataFactory.createStandardTorrent(name: "Banana", progress: 0.5)
			]
			let sortOption = SortOption(property: .progress, direction: .ascending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 3)
			// When progress is equal, should sort by name as secondary sort
			// This ensures consistent ordering even when primary sort values are identical
			#expect(result[0].name == "Apple")
			#expect(result[1].name == "Banana")
			#expect(result[2].name == "Zebra")
		}
		
		@Test("Sort stability with hash as final fallback")
		func sortStabilityWithHashAsFinalFallback() {
			// Arrange
			let hash1 = "aaaa"
			let hash2 = "bbbb"
			let torrents = [
				TestDataFactory.createStandardTorrent(hash: hash2, name: "Same Name", progress: 0.5),
				TestDataFactory.createStandardTorrent(hash: hash1, name: "Same Name", progress: 0.5)
			]
			let sortOption = SortOption(property: .progress, direction: .ascending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 2)
			// When name and progress are equal, should sort by hash
			#expect(result[0].hash == hash1)
			#expect(result[1].hash == hash2)
		}
		
		@Test("Sort with empty torrent list")
		func sortWithEmptyTorrentList() {
			// Arrange
			let torrents: [StandardTorrent] = []
			let sortOption = SortOption(property: .name, direction: .ascending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.isEmpty)
		}
		
		@Test("Sort with single torrent")
		func sortWithSingleTorrent() {
			// Arrange
			let torrents = [TestDataFactory.createStandardTorrent(name: "Single")]
			let sortOption = SortOption(property: .name, direction: .ascending)
			
			// Act
			let result = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
			
			// Assert
			#expect(result.count == 1)
			#expect(result[0].name == "Single")
		}
	}
}
