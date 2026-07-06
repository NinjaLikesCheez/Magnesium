import Foundation
import Testing

@testable import TorrentCore
@testable import TorrentMapping

// TODO: I don't know that these are great tests but... yeah
@Suite("TorrentMapper Performance Tests")
@MainActor
struct TorrentMapperPerformanceTests {

	// MARK: - Filtering Performance Tests
	@Test("Filtering performance with 1000+ torrents should complete under 100ms")
	func filteringPerformanceWithLargeTorrentList() {
		// Arrange
		let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
		let filterOptions = TorrentFilterOptions(
			states: [.downloading, .seeding],
			labels: ["movies", "tv-shows"]
		)
		let sortOption = TorrentSortOption(property: .name, direction: .ascending)

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			_ = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: filterOptions)
		}

		#expect(elapsed < .milliseconds(100), "Filtering 1000 torrents should complete in under 100ms, took \(elapsed)")
	}

	@Test("State filtering performance with large dataset")
	func stateFilteringPerformance() {
		// Arrange
		let torrents = TestDataFactory.createMultipleTorrents(count: 2000)
		let filterOptions = TorrentFilterOptions(states: [.downloading, .seeding, .paused])
		let sortOption = TorrentSortOption(property: .name, direction: .ascending)

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			_ = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: filterOptions)
		}

		#expect(
			elapsed < .milliseconds(150), "State filtering 2000 torrents should complete in under 150ms, took \(elapsed)")
	}

	@Test("Label filtering performance with large dataset")
	func labelFilteringPerformance() {
		// Arrange
		let torrents = TestDataFactory.createMultipleTorrents(count: 1500)
		let filterOptions = TorrentFilterOptions(labels: ["movies", "tv-shows", "music", "games", "software"])
		let sortOption = TorrentSortOption(property: .name, direction: .ascending)

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			_ = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: filterOptions)
		}

		#expect(
			elapsed < .milliseconds(120), "Label filtering 1500 torrents should complete in under 120ms, took \(elapsed)")
	}

	@Test("Search filtering performance with large dataset")
	func searchFilteringPerformance() {
		// Arrange
		let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
		let searchQuery = "Test Movie"
		let sortOption = TorrentSortOption(property: .name, direction: .ascending)

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			_ = TorrentMapper.map(torrents, query: searchQuery, sortOption: sortOption, filterOptions: TorrentFilterOptions())
		}

		#expect(
			elapsed < .milliseconds(200), "Search filtering 1000 torrents should complete in under 200ms, took \(elapsed)")
	}

	// MARK: - Sorting Performance Tests

	@Test("Name sorting performance with large dataset")
	func nameSortingPerformance() {
		// Arrange
		let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
		let sortOption = TorrentSortOption(property: .name, direction: .ascending)

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			_ = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: TorrentFilterOptions())
		}

		#expect(elapsed < .milliseconds(100), "Name sorting 1000 torrents should complete in under 100ms, took \(elapsed)")
	}

	@Test("Date sorting performance with large dataset")
	func dateSortingPerformance() {
		// Arrange
		let torrents = TestDataFactory.createMultipleTorrents(count: 1500)
		let sortOption = TorrentSortOption(property: .dateAdded, direction: .descending)

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			_ = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: TorrentFilterOptions())
		}

		#expect(elapsed < .milliseconds(80), "Date sorting 1500 torrents should complete in under 80ms, took \(elapsed)")
	}

	@Test("Speed sorting performance with large dataset")
	func speedSortingPerformance() {
		// Arrange
		let torrents = TestDataFactory.createMultipleTorrents(count: 1200)
		let downloadSortOption = TorrentSortOption(property: .downloadSpeed, direction: .descending)
		let uploadSortOption = TorrentSortOption(property: .uploadSpeed, direction: .descending)

		// Act & Assert - Download Speed
		let clock = ContinuousClock()
		let downloadElapsed = clock.measure {
			_ = TorrentMapper.map(torrents, query: "", sortOption: downloadSortOption, filterOptions: TorrentFilterOptions())
		}

		let uploadElapsed = clock.measure {
			_ = TorrentMapper.map(torrents, query: "", sortOption: uploadSortOption, filterOptions: TorrentFilterOptions())
		}

		#expect(
			downloadElapsed < .milliseconds(90),
			"Download speed sorting 1200 torrents should complete in under 90ms, took \(downloadElapsed)")
		#expect(
			uploadElapsed < .milliseconds(90),
			"Upload speed sorting 1200 torrents should complete in under 90ms, took \(uploadElapsed)")
	}

	@Test("Progress sorting performance with large dataset")
	func progressSortingPerformance() {
		// Arrange
		let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
		let sortOption = TorrentSortOption(property: .progress, direction: .descending)

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			_ = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: TorrentFilterOptions())
		}

		#expect(
			elapsed < .milliseconds(85), "Progress sorting 1000 torrents should complete in under 85ms, took \(elapsed)")
	}

	// MARK: - Combined Operations Performance Tests

	@Test("Combined filter, sort, and search performance")
	func combinedOperationsPerformance() {
		// Arrange
		let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
		let filterOptions = TorrentFilterOptions(
			states: [.downloading, .seeding],
			labels: ["movies"]
		)
		let sortOption = TorrentSortOption(property: .name, direction: .ascending)
		let searchQuery = "Test"

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			_ = TorrentMapper.map(torrents, query: searchQuery, sortOption: sortOption, filterOptions: filterOptions)
		}

		#expect(
			elapsed < .milliseconds(200),
			"Combined operations on 1000 torrents should complete in under 200ms, took \(elapsed)")
	}

	@Test("Complex combined operations performance")
	func complexCombinedOperationsPerformance() {
		// Arrange
		let torrents = TestDataFactory.createMultipleTorrents(count: 2000)
		let filterOptions = TorrentFilterOptions(
			states: Set(StandardTorrentState.allCases),
			labels: ["movies", "tv-shows", "music", "games", "software", "books"]
		)
		let sortOption = TorrentSortOption(property: .downloadSpeed, direction: .descending)
		let searchQuery = "Movie Series Game"

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			_ = TorrentMapper.map(torrents, query: searchQuery, sortOption: sortOption, filterOptions: filterOptions)
		}

		#expect(
			elapsed < .milliseconds(300),
			"Complex combined operations on 2000 torrents should complete in under 300ms, took \(elapsed)")
	}

	// MARK: - Stress Tests
	@Test("Stress test with very large dataset")
	func stressTestWithVeryLargeDataset() {
		// Arrange
		let torrents = TestDataFactory.createMultipleTorrents(count: 10000)
		let filterOptions = TorrentFilterOptions(
			states: [.downloading, .seeding, .paused],
			labels: ["movies", "tv-shows"]
		)
		let sortOption = TorrentSortOption(property: .name, direction: .ascending)

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			_ = TorrentMapper.map(torrents, query: "Test", sortOption: sortOption, filterOptions: filterOptions)
		}

		#expect(
			elapsed < .milliseconds(1000), "Processing 10,000 torrents should complete in under 1 second, took \(elapsed)")
	}

	@Test("Repeated operations performance consistency")
	func repeatedOperationsPerformanceConsistency() {
		// Arrange
		let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
		let filterOptions = TorrentFilterOptions(states: [.downloading])
		let sortOption = TorrentSortOption(property: .name)
		var measurements: [Duration] = []

		// Act - Perform same operation multiple times
		let clock = ContinuousClock()
		for _ in 0..<20 {
			let elapsed = clock.measure {
				_ = TorrentMapper.map(torrents, query: "Test", sortOption: sortOption, filterOptions: filterOptions)
			}
			measurements.append(elapsed)
		}

		// Assert - Performance should be consistent
		let maxTime = measurements.max() ?? .zero
		let minTime = measurements.min() ?? .zero
		let variance = maxTime - minTime

		#expect(variance < .milliseconds(50), "Performance variance should be under 50ms, variance was \(variance)")
		#expect(maxTime < .milliseconds(150), "Maximum time should be under 150ms, was \(maxTime)")
	}
}
