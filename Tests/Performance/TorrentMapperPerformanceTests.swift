import Testing
import Foundation
@testable import Magnesium

@Suite("TorrentMapper Performance Tests")
struct TorrentMapperPerformanceTests {
    
    // MARK: - Filtering Performance Tests
    
    @Test("Filtering performance with 1000+ torrents should complete under 100ms")
    func filteringPerformanceWithLargeTorrentList() {
        // Arrange
        let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
        let filterOptions = FilterOptions(
            states: [.downloading, .seeding],
            labels: ["movies", "tv-shows"]
        )
        
        // Act & Assert
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = TorrentMapper.filter(torrents, using: filterOptions, query: "")
        }
        
        #expect(elapsed < .milliseconds(100), "Filtering 1000 torrents should complete in under 100ms, took \(elapsed)")
    }
    
    @Test("State filtering performance with large dataset")
    func stateFilteringPerformance() {
        // Arrange
        let torrents = TestDataFactory.createMultipleTorrents(count: 2000)
        let filterOptions = FilterOptions(states: [.downloading, .seeding, .paused])
        
        // Act & Assert
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = TorrentMapper.filter(torrents, using: filterOptions, query: "")
        }
        
        #expect(elapsed < .milliseconds(150), "State filtering 2000 torrents should complete in under 150ms, took \(elapsed)")
    }
    
    @Test("Label filtering performance with large dataset")
    func labelFilteringPerformance() {
        // Arrange
        let torrents = TestDataFactory.createMultipleTorrents(count: 1500)
        let filterOptions = FilterOptions(labels: ["movies", "tv-shows", "music", "games", "software"])
        
        // Act & Assert
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = TorrentMapper.filter(torrents, using: filterOptions, query: "")
        }
        
        #expect(elapsed < .milliseconds(120), "Label filtering 1500 torrents should complete in under 120ms, took \(elapsed)")
    }
    
    @Test("Search filtering performance with large dataset")
    func searchFilteringPerformance() {
        // Arrange
        let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
        let searchQuery = "Test Movie"
        
        // Act & Assert
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = TorrentMapper.filter(torrents, using: FilterOptions(), query: searchQuery)
        }
        
        #expect(elapsed < .milliseconds(200), "Search filtering 1000 torrents should complete in under 200ms, took \(elapsed)")
    }
    
    // MARK: - Sorting Performance Tests
    
    @Test("Name sorting performance with large dataset")
    func nameSortingPerformance() {
        // Arrange
        let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
        let sortOption = SortOption(property: .name, direction: .ascending)
        
        // Act & Assert
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
        }
        
        #expect(elapsed < .milliseconds(100), "Name sorting 1000 torrents should complete in under 100ms, took \(elapsed)")
    }
    
    @Test("Date sorting performance with large dataset")
    func dateSortingPerformance() {
        // Arrange
        let torrents = TestDataFactory.createMultipleTorrents(count: 1500)
        let sortOption = SortOption(property: .dateAdded, direction: .descending)
        
        // Act & Assert
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
        }
        
        #expect(elapsed < .milliseconds(80), "Date sorting 1500 torrents should complete in under 80ms, took \(elapsed)")
    }
    
    @Test("Speed sorting performance with large dataset")
    func speedSortingPerformance() {
        // Arrange
        let torrents = TestDataFactory.createMultipleTorrents(count: 1200)
        let downloadSortOption = SortOption(property: .downloadSpeed, direction: .descending)
        let uploadSortOption = SortOption(property: .uploadSpeed, direction: .descending)
        
        // Act & Assert - Download Speed
        let clock = ContinuousClock()
        let downloadElapsed = clock.measure {
            _ = TorrentMapper.map(torrents, query: "", sortOption: downloadSortOption, filterOptions: FilterOptions())
        }
        
        let uploadElapsed = clock.measure {
            _ = TorrentMapper.map(torrents, query: "", sortOption: uploadSortOption, filterOptions: FilterOptions())
        }
        
        #expect(downloadElapsed < .milliseconds(90), "Download speed sorting 1200 torrents should complete in under 90ms, took \(downloadElapsed)")
        #expect(uploadElapsed < .milliseconds(90), "Upload speed sorting 1200 torrents should complete in under 90ms, took \(uploadElapsed)")
    }
    
    @Test("Progress sorting performance with large dataset")
    func progressSortingPerformance() {
        // Arrange
        let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
        let sortOption = SortOption(property: .progress, direction: .descending)
        
        // Act & Assert
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: FilterOptions())
        }
        
        #expect(elapsed < .milliseconds(85), "Progress sorting 1000 torrents should complete in under 85ms, took \(elapsed)")
    }
    
    // MARK: - Combined Operations Performance Tests
    
    @Test("Combined filter, sort, and search performance")
    func combinedOperationsPerformance() {
        // Arrange
        let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
        let filterOptions = FilterOptions(
            states: [.downloading, .seeding],
            labels: ["movies"]
        )
        let sortOption = SortOption(property: .name, direction: .ascending)
        let searchQuery = "Test"
        
        // Act & Assert
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = TorrentMapper.map(torrents, query: searchQuery, sortOption: sortOption, filterOptions: filterOptions)
        }
        
        #expect(elapsed < .milliseconds(200), "Combined operations on 1000 torrents should complete in under 200ms, took \(elapsed)")
    }
    
    @Test("Complex combined operations performance")
    func complexCombinedOperationsPerformance() {
        // Arrange
        let torrents = TestDataFactory.createMultipleTorrents(count: 2000)
        let filterOptions = FilterOptions(
            states: Set(TorrentState.allCases),
            labels: ["movies", "tv-shows", "music", "games", "software", "books"]
        )
        let sortOption = SortOption(property: .downloadSpeed, direction: .descending)
        let searchQuery = "Movie Series Game"
        
        // Act & Assert
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = TorrentMapper.map(torrents, query: searchQuery, sortOption: sortOption, filterOptions: filterOptions)
        }
        
        #expect(elapsed < .milliseconds(300), "Complex combined operations on 2000 torrents should complete in under 300ms, took \(elapsed)")
    }
    
    // MARK: - Memory Usage Tests
    
    @Test("Memory efficiency during large torrent list processing")
    func memoryEfficiencyDuringLargeProcessing() {
        // Arrange
        let initialMemory = getMemoryUsage()
        let torrents = TestDataFactory.createMultipleTorrents(count: 5000)
        let afterCreationMemory = getMemoryUsage()
        
        // Act - Perform multiple operations
        let filterOptions = FilterOptions(states: [.downloading, .seeding])
        let sortOption = SortOption(property: .name, direction: .ascending)
        
        for _ in 0..<10 {
            _ = TorrentMapper.map(torrents, query: "Test", sortOption: sortOption, filterOptions: filterOptions)
        }
        
        let afterOperationsMemory = getMemoryUsage()
        
        // Assert - Memory should not grow excessively during operations
        let memoryGrowthDuringOperations = afterOperationsMemory - afterCreationMemory
        let expectedMaxGrowth: UInt64 = 50 * 1024 * 1024 // 50MB max growth
        
        #expect(memoryGrowthDuringOperations < expectedMaxGrowth, 
                "Memory growth during operations should be under 50MB, grew by \(memoryGrowthDuringOperations / 1024 / 1024)MB")
    }
    
    @Test("Memory cleanup after operations")
    func memoryCleanupAfterOperations() {
        // Arrange
        let initialMemory = getMemoryUsage()
        
        // Act - Create and process large dataset in scope
        do {
            let torrents = TestDataFactory.createMultipleTorrents(count: 3000)
            let filterOptions = FilterOptions(states: [.downloading])
            let sortOption = SortOption(property: .dateAdded)
            
            _ = TorrentMapper.map(torrents, query: "", sortOption: sortOption, filterOptions: filterOptions)
        }
        
        // Force garbage collection
        autoreleasepool { }
        
        let afterOperationsMemory = getMemoryUsage()
        let memoryGrowth = afterOperationsMemory - initialMemory
        let expectedMaxGrowth: UInt64 = 100 * 1024 * 1024 // 100MB max growth
        
        // Assert - Memory should be cleaned up
        #expect(memoryGrowth < expectedMaxGrowth, 
                "Memory should be cleaned up after operations, grew by \(memoryGrowth / 1024 / 1024)MB")
    }
    
    // MARK: - Stress Tests
    
    @Test("Stress test with very large dataset")
    func stressTestWithVeryLargeDataset() {
        // Arrange
        let torrents = TestDataFactory.createMultipleTorrents(count: 10000)
        let filterOptions = FilterOptions(
            states: [.downloading, .seeding, .paused],
            labels: ["movies", "tv-shows"]
        )
        let sortOption = SortOption(property: .name, direction: .ascending)
        
        // Act & Assert
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = TorrentMapper.map(torrents, query: "Test", sortOption: sortOption, filterOptions: filterOptions)
        }
        
        #expect(elapsed < .milliseconds(1000), "Processing 10,000 torrents should complete in under 1 second, took \(elapsed)")
    }
    
    @Test("Repeated operations performance consistency")
    func repeatedOperationsPerformanceConsistency() {
        // Arrange
        let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
        let filterOptions = FilterOptions(states: [.downloading])
        let sortOption = SortOption(property: .name)
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

// MARK: - Helper Functions

private func getMemoryUsage() -> UInt64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    
    return result == KERN_SUCCESS ? info.resident_size : 0
}