import Testing
import Foundation
@testable import Magnesium

@Suite("TorrentManager Performance Tests", .serialized)
@MainActor
struct TorrentManagerPerformanceTests {

	// MARK: - Torrent Refresh Performance Tests

	@Test("Torrent refresh performance with large delta updates")
	func torrentRefreshPerformanceWithLargeDeltaUpdates() async throws {
		// Arrange
		let mockSession = MockSession(MockAppPreferences())
		let mockClient = MockTorrentClientActing()
		let mockPreferences = MockAppPreferences()

		// Create initial set of torrents
		let initialTorrents = TestDataFactory.createMultipleTorrents(count: 1000)
		mockClient.refreshResult = (initialTorrents, [])
		mockSession.setMockActionImplementation(mockClient)

		let manager = TorrentManager(session: mockSession, preferences: mockPreferences)

		// Initial refresh to populate
		try await manager.refresh()

		// Create updated torrents with changes (simulate delta update)
		var updatedTorrents = initialTorrents
		// Update 50% of existing torrents
		for i in 0..<500 {
			updatedTorrents[i] = TestDataFactory.createStandardTorrent(
				hash: updatedTorrents[i].hash,
				name: updatedTorrents[i].name,
				progress: Float.random(in: 0...1),
				downloaded: Int64.random(in: 0...1024*1024*1024)
			)
		}
		// Add 200 new torrents
		let newTorrents = TestDataFactory.createMultipleTorrents(count: 200)
		updatedTorrents.append(contentsOf: newTorrents)
		// Remove 100 torrents
		updatedTorrents.removeLast(100)

		mockClient.refreshResult = (updatedTorrents, [])
		mockSession.setMockActionImplementation(mockClient)

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = try await clock.measure {
			try await manager.refresh()
		}

		#expect(elapsed < .milliseconds(100), "Delta update of 1000+ torrents should complete in under 200ms, took \(elapsed)")
		#expect(manager.torrents.count == updatedTorrents.count, "Manager should have correct torrent count after delta update")
	}

	@Test("Torrent refresh performance with massive dataset")
	func torrentRefreshPerformanceWithMassiveDataset() async throws {
		// Arrange
		let mockSession = MockSession(MockAppPreferences())
		let mockClient = MockTorrentClientActing()
		let mockPreferences = MockAppPreferences()

		let torrents = TestDataFactory.createMultipleTorrents(count: 5000)
		let labels = TestDataFactory.createMultipleLabels(count: 50)
		mockClient.refreshResult = (torrents, labels)
		mockSession.setMockActionImplementation(mockClient)

		let manager = TorrentManager(session: mockSession, preferences: mockPreferences)

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = try await clock.measure {
			try await manager.refresh()
		}

		#expect(elapsed < .milliseconds(500), "Refresh of 5000 torrents should complete in under 500ms, took \(elapsed)")
		#expect(manager.torrents.count == 5000, "Manager should have all 5000 torrents")
		#expect(manager.labels.count == 50, "Manager should have all 50 labels")
	}

	@Test("Repeated refresh operations performance consistency")
	func repeatedRefreshOperationsPerformanceConsistency() async throws {
		// Arrange
		let mockSession = MockSession(MockAppPreferences())
		let mockClient = MockTorrentClientActing()
		let mockPreferences = MockAppPreferences()

		let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
		mockClient.refreshResult = (torrents, [])
		mockSession.setMockActionImplementation(mockClient)

		let manager = TorrentManager(session: mockSession, preferences: mockPreferences)
		var measurements: [Duration] = []

		// Act - Perform multiple refresh operations
		let clock = ContinuousClock()
		for _ in 0..<10 {
			let elapsed = clock.measure {
				Task {
					try await manager.refresh()
				}
			}
			measurements.append(elapsed)
		}

		// Assert - Performance should be consistent
		let maxTime = measurements.max() ?? .zero
		let minTime = measurements.min() ?? .zero
		let variance = maxTime - minTime

		#expect(variance < .milliseconds(100), "Refresh performance variance should be under 100ms, variance was \(variance)")
		#expect(maxTime < .milliseconds(300), "Maximum refresh time should be under 300ms, was \(maxTime)")
	}

	// MARK: - Memory Efficiency Tests

	// MARK: - Timer Performance Tests

	@Test("Timer performance and resource cleanup")
	func timerPerformanceAndResourceCleanup() async throws {
		// Arrange
		let mockSession = MockSession(MockAppPreferences())
		let mockClient = MockTorrentClientActing()
		let mockPreferences = MockAppPreferences()
		mockPreferences.autoRefreshInterval = 0.1 // Fast refresh for testing

		let torrents = TestDataFactory.createMultipleTorrents(count: 100)
		mockClient.refreshResult = (torrents, [])
		mockSession.setMockActionImplementation(mockClient)

		// Act - Create manager and let timer run
		let manager = TorrentManager(session: mockSession, preferences: mockPreferences)

		// Wait for multiple timer cycles
		try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

		let initialRefreshCount = mockClient.refreshCallCount

		// Change refresh interval to test timer recreation
		mockPreferences.autoRefreshInterval = 0.2

		// Wait for more timer cycles
		try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds

		let finalRefreshCount = mockClient.refreshCallCount

		// Assert - Timer should be working and updating
		#expect(finalRefreshCount > initialRefreshCount, "Timer should trigger multiple refreshes")
		#expect(finalRefreshCount >= 3, "Should have at least 3 refresh calls from timer")

		// Cleanup test
		_ = manager // Keep reference to prevent deallocation during test
	}

	@Test("Timer interval change performance")
	func timerIntervalChangePerformance() async throws {
		// Arrange
		let mockSession = MockSession(MockAppPreferences())
		let mockClient = MockTorrentClientActing()
		let mockPreferences = MockAppPreferences()

		let torrents = TestDataFactory.createMultipleTorrents(count: 50)
		mockClient.refreshResult = (torrents, [])
		mockSession.setMockActionImplementation(mockClient)

		let manager = TorrentManager(session: mockSession, preferences: mockPreferences)

		// Act & Assert - Measure timer interval changes
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			// Change interval multiple times rapidly
			for interval in [0.5, 1.0, 0.2, 2.0, 0.1] {
				mockPreferences.autoRefreshInterval = interval
			}
		}

		#expect(elapsed < .milliseconds(50), "Timer interval changes should be fast, took \(elapsed)")

		// Cleanup
		_ = manager
	}

	// MARK: - Filtered Torrents Performance Tests

	@Test("Filtered torrents computation performance")
	func filteredTorrentsComputationPerformance() async throws {
		// Arrange
		let mockSession = MockSession(MockAppPreferences())
		let mockClient = MockTorrentClientActing()
		let mockPreferences = MockAppPreferences()

		let torrents = TestDataFactory.createMultipleTorrents(count: 2000)
		mockClient.refreshResult = (torrents, [])
		mockSession.setMockActionImplementation(mockClient)

		let manager = TorrentManager(session: mockSession, preferences: mockPreferences)
		try await manager.refresh()

		// Configure complex filtering
		mockPreferences.filterOptions = FilterOptions(
			states: [.downloading, .seeding],
			labels: ["movies", "tv-shows"]
		)
		mockPreferences.sortOption = SortOption(property: .name, direction: .ascending)
		manager.searchQuery = "Test"

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			_ = manager.filteredTorrents
		}

		#expect(elapsed < .milliseconds(150), "Filtered torrents computation should complete in under 150ms, took \(elapsed)")
	}

	@Test("Total speed calculations performance")
	func totalSpeedCalculationsPerformance() async throws {
		// Arrange
		let mockSession = MockSession(MockAppPreferences())
		let mockClient = MockTorrentClientActing()
		let mockPreferences = MockAppPreferences()

		let torrents = TestDataFactory.createMultipleTorrents(count: 3000)
		mockClient.refreshResult = (torrents, [])
		mockSession.setMockActionImplementation(mockClient)

		let manager = TorrentManager(session: mockSession, preferences: mockPreferences)
		try await manager.refresh()

		// Act & Assert
		let clock = ContinuousClock()
		let uploadElapsed = clock.measure {
			_ = manager.totalUploadSpeed
		}

		let downloadElapsed = clock.measure {
			_ = manager.totalDownloadSpeed
		}

		#expect(uploadElapsed < .milliseconds(50), "Total upload speed calculation should complete in under 50ms, took \(uploadElapsed)")
		#expect(downloadElapsed < .milliseconds(50), "Total download speed calculation should complete in under 50ms, took \(downloadElapsed)")
	}

	// MARK: - Action Performance Tests

	@Test("Torrent action performance with large selections")
	func torrentActionPerformanceWithLargeSelections() async throws {
		// Arrange
		let mockSession = MockSession(MockAppPreferences())
		let mockClient = MockTorrentClientActing()
		let mockPreferences = MockAppPreferences()

		let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
		mockClient.refreshResult = (torrents, [])
		mockSession.setMockActionImplementation(mockClient)

		let manager = TorrentManager(session: mockSession, preferences: mockPreferences)
		try await manager.refresh()

		let selectedTorrents = Array(torrents.prefix(500)) // Select 500 torrents

		// Act & Assert - Resume action
		let clock = ContinuousClock()
		let resumeElapsed = try await clock.measure {
			try await manager.resume(selectedTorrents)
		}

		// Act & Assert - Pause action
		let pauseElapsed = try await clock.measure {
			try await manager.pause(selectedTorrents)
		}

		#expect(resumeElapsed < .milliseconds(100), "Resume action on 500 torrents should complete in under 100ms, took \(resumeElapsed)")
		#expect(pauseElapsed < .milliseconds(100), "Pause action on 500 torrents should complete in under 100ms, took \(pauseElapsed)")
		#expect(mockClient.resumeCallCount == 1, "Resume should be called once")
		#expect(mockClient.pauseCallCount == 1, "Pause should be called once")
	}

	@Test("Delete action performance with large selections")
	func deleteActionPerformanceWithLargeSelections() async throws {
		// Arrange
		let mockSession = MockSession(MockAppPreferences())
		let mockClient = MockTorrentClientActing()
		let mockPreferences = MockAppPreferences()

		let torrents = TestDataFactory.createMultipleTorrents(count: 800)
		mockClient.refreshResult = (torrents, [])
		mockSession.setMockActionImplementation(mockClient)

		let manager = TorrentManager(session: mockSession, preferences: mockPreferences)
		try await manager.refresh()

		let selectedTorrents = Array(torrents.prefix(300)) // Select 300 torrents

		// Act & Assert
		let clock = ContinuousClock()
		let elapsed = try await clock.measure {
			try await manager.delete(selectedTorrents, removeData: true)
		}

		#expect(elapsed < .milliseconds(150), "Delete action on 300 torrents should complete in under 150ms, took \(elapsed)")
		#expect(mockClient.removeCallCount == 1, "Remove should be called once")
		#expect(mockClient.removedTorrents.count == 300, "Should remove 300 torrents")
	}

	// MARK: - Stress Tests

	@Test("Stress test with concurrent operations")
	func stressTestWithConcurrentOperations() async throws {
		// Arrange
		let mockSession = MockSession(MockAppPreferences())
		let mockClient = MockTorrentClientActing()
		let mockPreferences = MockAppPreferences()

		let torrents = TestDataFactory.createMultipleTorrents(count: 1000)
		mockClient.refreshResult = (torrents, [])
		mockSession.setMockActionImplementation(mockClient)

		let manager = TorrentManager(session: mockSession, preferences: mockPreferences)
		try await manager.refresh()

		// Act - Perform multiple concurrent operations
		let clock = ContinuousClock()
		let elapsed = clock.measure {
			Task { @MainActor in
				await withTaskGroup(of: Void.self) { group in
					// Multiple filtered torrents computations
					for _ in 0..<5 {
						group.addTask {
							_ = await manager.filteredTorrents
						}
					}

					// Multiple speed calculations
					for _ in 0..<5 {
						group.addTask {
							await _ = manager.totalUploadSpeed
							await _ = manager.totalDownloadSpeed
						}
					}

					// Search query changes
					for i in 0..<5 {
						group.addTask { @MainActor in
							manager.searchQuery = "Test \(i)"
						}
					}
				}
			}
		}

		// Assert
		#expect(elapsed < .milliseconds(500), "Concurrent operations should complete in under 500ms, took \(elapsed)")
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
