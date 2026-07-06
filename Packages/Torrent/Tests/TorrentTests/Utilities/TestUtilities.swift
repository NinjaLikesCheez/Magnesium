import Foundation
import Testing

@testable import TorrentCore

/// Utility functions and helpers for testing
struct TestUtilities {

	// MARK: - Assertion Helpers

	/// Helper to test floating point equality with tolerance
	static func expectEqual<T: FloatingPoint>(
		_ actual: T,
		_ expected: T,
		tolerance: T = 0.001,
		file: StaticString = #file,
		line: UInt = #line
	) {
		let difference = abs(actual - expected)
		#expect(
			difference <= tolerance,
			"Expected \(actual) to equal \(expected) within tolerance \(tolerance), but difference was \(difference)",
			sourceLocation: SourceLocation(fileID: file.description, filePath: file.description, line: Int(line), column: 0)
		)
	}

	/// Helper to test that a collection contains expected elements in any order
	static func expectContains<T: Equatable>(
		_ collection: [T],
		_ expectedElements: [T],
		file: StaticString = #file,
		line: UInt = #line
	) {
		for element in expectedElements {
			#expect(
				collection.contains(element),
				"Expected collection to contain \(element)",
				sourceLocation: SourceLocation(fileID: file.description, filePath: file.description, line: Int(line), column: 0)
			)
		}
	}

	/// Helper to test that a collection is sorted according to a predicate
	static func expectSorted<T>(
		_ collection: [T],
		by predicate: (T, T) -> Bool,
		file: StaticString = #file,
		line: UInt = #line
	) {
		for i in 0..<(collection.count - 1) {
			#expect(
				predicate(collection[i], collection[i + 1]),
				"Collection is not sorted at index \(i)",
				sourceLocation: SourceLocation(fileID: file.description, filePath: file.description, line: Int(line), column: 0)
			)
		}
	}

	// MARK: - Performance Testing Helpers

	/// Measures execution time of a closure and expects it to be under a threshold
	static func expectPerformance<T>(
		under threshold: Duration,
		operation: () throws -> T,
		file: StaticString = #file,
		line: UInt = #line
	) rethrows -> T {
		let clock = ContinuousClock()
		let start = clock.now
		let result = try operation()
		let elapsed = clock.now.duration(to: start)

		#expect(
			elapsed < threshold,
			"Operation took \(elapsed), expected under \(threshold)",
			sourceLocation: SourceLocation(fileID: file.description, filePath: file.description, line: Int(line), column: 0)
		)

		return result
	}

	/// Measures execution time of an async closure and expects it to be under a threshold
	static func expectAsyncPerformance<T>(
		under threshold: Duration,
		operation: () async throws -> T,
		file: StaticString = #file,
		line: UInt = #line
	) async rethrows -> T {
		let clock = ContinuousClock()
		let start = clock.now
		let result = try await operation()
		let elapsed = clock.now.duration(to: start)

		#expect(
			elapsed < threshold,
			"Async operation took \(elapsed), expected under \(threshold)",
			sourceLocation: SourceLocation(fileID: file.description, filePath: file.description, line: Int(line), column: 0)
		)

		return result
	}

	// MARK: - Data Validation Helpers

	/// Validates that a StandardTorrent has consistent data
	@MainActor
	static func validateTorrentConsistency(
		_ torrent: StandardTorrent,
		file: StaticString = #file,
		line: UInt = #line
	) {
		let sourceLocation = SourceLocation(
			fileID: file.description, filePath: file.description, line: Int(line), column: 0)

		// Progress should be between 0 and 1
		#expect(
			torrent.progress >= 0 && torrent.progress <= 1,
			"Progress should be between 0 and 1",
			sourceLocation: sourceLocation)

		// Downloaded should not exceed size
		#expect(
			torrent.downloaded <= torrent.size,
			"Downloaded should not exceed total size",
			sourceLocation: sourceLocation)

		// Speeds should be non-negative
		#expect(
			torrent.downloadRate >= 0,
			"Download speed should be non-negative",
			sourceLocation: sourceLocation)
		#expect(
			torrent.uploadRate >= 0,
			"Upload speed should be non-negative",
			sourceLocation: sourceLocation)

		// Name should not be empty
		#expect(
			!torrent.name.isEmpty,
			"Torrent name should not be empty",
			sourceLocation: sourceLocation)

		// ID should not be empty
		#expect(
			!torrent.id.isEmpty,
			"Torrent ID should not be empty",
			sourceLocation: sourceLocation)
	}

	/// Validates that a collection of torrents maintains consistency
	@MainActor
	static func validateTorrentCollectionConsistency(
		_ torrents: [StandardTorrent],
		file: StaticString = #file,
		line: UInt = #line
	) {
		let sourceLocation = SourceLocation(
			fileID: file.description, filePath: file.description, line: Int(line), column: 0)

		// All torrents should have unique IDs
		let ids = torrents.map(\.id)
		let uniqueIds = Set(ids)
		#expect(
			ids.count == uniqueIds.count,
			"All torrents should have unique IDs",
			sourceLocation: sourceLocation)

		// Validate each torrent individually
		for torrent in torrents {
			validateTorrentConsistency(torrent, file: file, line: line)
		}
	}
}

// MARK: - Test Configuration

/// Configuration values for tests
enum TestConfiguration {
	static let defaultPerformanceThreshold: Duration = .milliseconds(100)
	static let largeDatasetSize = 1000
	static let smallDatasetSize = 10
	static let floatingPointTolerance: Float = 0.001
}

// MARK: - Custom Test Traits

/// Trait for performance tests
struct PerformanceTest: TestTrait {
	static let name = "Performance"
}

/// Trait for integration tests
struct IntegrationTest: TestTrait {
	static let name = "Integration"
}

/// Trait for edge case tests
struct EdgeCaseTest: TestTrait {
	static let name = "EdgeCase"
}
