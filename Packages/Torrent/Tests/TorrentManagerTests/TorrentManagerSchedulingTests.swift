import Common
import Foundation
import Testing

@testable import TorrentManager
@testable import TorrentPreferences
@testable import TorrentTestSupport

@Suite("TorrentManager Scheduling Tests")
@MainActor
class TorrentManagerSchedulingTests {
	private let suiteName = "test-\(UUID().uuidString)"
	private let testDefaults: UserDefaults
	private let mockPreferences: TorrentPreferences
	private let mockSession: MockTorrentSession
	private let mockClient: MockTorrentClient
	private let fakeScheduler: FakeTorrentScheduler
	private let torrentManager: TorrentManager

	init() {
		testDefaults = UserDefaults(suiteName: suiteName)!
		mockPreferences = TorrentPreferences(userDefaults: testDefaults, keychain: InMemoryKeychain())
		mockSession = MockTorrentSession(TorrentPreferences(keychain: InMemoryKeychain()))
		mockClient = MockTorrentClient()
		fakeScheduler = FakeTorrentScheduler()

		mockSession.setMockClient(mockClient)

		torrentManager = TorrentManager(session: mockSession, preferences: mockPreferences, scheduling: fakeScheduler)
	}

	deinit {
		UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
	}

	@Test("TorrentManager initializes with timer based on preferences")
	func torrentManagerInitializesWithTimerBasedOnPreferences() async throws {
		// The initial schedule happens on the first iteration of an async observation loop, not synchronously in init
		try await Task.sleep(for: .milliseconds(50))

		// Verify that the manager scheduled a refresh at the preferences' configured interval
		#expect(fakeScheduler.scheduledIntervals == [mockPreferences.autoRefreshInterval])
	}

	@Test("Firing the scheduled interval triggers a refresh")
	func firingScheduledIntervalTriggersRefresh() async throws {
		// Arrange
		let testTorrents = TestDataFactory.createMultipleTorrents(count: 2)
		mockClient.refreshResult = (testTorrents, [])
		// The initial schedule happens on the first iteration of an async observation loop, not synchronously in init
		try await Task.sleep(for: .milliseconds(50))

		// Act
		fakeScheduler.fire()
		try await Task.sleep(for: .milliseconds(10))

		// Assert
		#expect(mockClient.refreshCallCount == 1)
	}

	@Test("Firing the scheduled interval multiple times refreshes each time")
	func firingScheduledIntervalMultipleTimesRefreshesEachTime() async throws {
		// Arrange
		mockClient.refreshResult = ([], [])
		try await Task.sleep(for: .milliseconds(50))

		// Act
		fakeScheduler.fire(times: 3)
		try await Task.sleep(for: .milliseconds(10))

		// Assert
		#expect(mockClient.refreshCallCount == 3)
	}

	@Test("Changing autoRefreshInterval reschedules with the new interval")
	func changingAutoRefreshIntervalReschedules() async throws {
		// Act
		mockPreferences.autoRefreshInterval = 5.0
		// Allow the Observations loop (a detached Task) to observe the change and reschedule
		try await Task.sleep(for: .milliseconds(50))

		// Assert
		#expect(fakeScheduler.scheduledIntervals.last == 5.0)
		#expect(fakeScheduler.activeScheduleCount == 1)
	}

	@Test("Setting autoRefreshInterval to zero cancels scheduling")
	func settingAutoRefreshIntervalToZeroCancelsScheduling() async throws {
		// Act
		mockPreferences.autoRefreshInterval = 0
		try await Task.sleep(for: .milliseconds(50))

		// Assert
		#expect(fakeScheduler.activeScheduleCount == 0)
	}
}
