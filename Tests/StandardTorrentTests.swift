import Foundation
import Testing
@testable import Magnesium

@Suite("StandardTorrent Tests")
struct StandardTorrentTests {
	// MARK: - Initialization Tests

	@Test("StandardTorrent initialization with all properties")
	func standardTorrentInitialization() {
		// Arrange
		let dateAdded = Date()
		let downloaded: Int64 = 1024 * 1024 * 500 // 500 MB
		let downloadPath = "/downloads/test"
		let downloadRate: Int64 = 1024 * 100 // 100 KB/s
		let eta: TimeInterval = 3600 // 1 hour
		let hash = "test-hash-123"
		let label = "test-label"
		let name = "Test Torrent"
		let peers = 5
		let progress: Float = 0.75
		let seeds = 10
		let seedingTime: TimeInterval = 7200 // 2 hours
		let size: Int64 = 1024 * 1024 * 1024 // 1 GB
		let state = TorrentState.downloading
		let totalPeers = 20
		let totalSeeds = 30
		let trackers = ["http://tracker1.example.com", "http://tracker2.example.com"]
		let uploaded: Int64 = 1024 * 1024 * 250 // 250 MB
		let uploadRate: Int64 = 1024 * 50 // 50 KB/s

		// Act
		let torrent = StandardTorrent(
			dateAdded: dateAdded,
			downloaded: downloaded,
			downloadPath: downloadPath,
			downloadRate: downloadRate,
			eta: eta,
			hash: hash,
			label: label,
			name: name,
			peers: peers,
			progress: progress,
			seeds: seeds,
			seedingTime: seedingTime,
			size: size,
			state: state,
			totalPeers: totalPeers,
			totalSeeds: totalSeeds,
			trackers: trackers,
			uploaded: uploaded,
			uploadRate: uploadRate
		)

		// Assert
		#expect(torrent.id == hash)
		#expect(torrent.dateAdded == dateAdded)
		#expect(torrent.downloaded == downloaded)
		#expect(torrent.downloadPath == downloadPath)
		#expect(torrent.downloadRate == downloadRate)
		#expect(torrent.eta == eta)
		#expect(torrent.hash == hash)
		#expect(torrent.label == label)
		#expect(torrent.name == name)
		#expect(torrent.peers == peers)
		#expect(torrent.progress == progress)
		#expect(torrent.seeds == seeds)
		#expect(torrent.seedingTime == seedingTime)
		#expect(torrent.size == size)
		#expect(torrent.state == state)
		#expect(torrent.totalPeers == totalPeers)
		#expect(torrent.totalSeeds == totalSeeds)
		#expect(torrent.trackers == trackers)
		#expect(torrent.uploaded == uploaded)
		#expect(torrent.uploadRate == uploadRate)
	}

	// MARK: - Update Method Tests

	@Test("StandardTorrent update method correctly updates all mutable properties")
	func standardTorrentUpdateMethod() {
		// Arrange
		let originalTorrent = TestDataFactory.createStandardTorrent(
			hash: "original-hash",
			name: "Original Torrent",
			state: .downloading,
			progress: 0.5
		)

		let updatedTorrent = TestDataFactory.createStandardTorrent(
			hash: "updated-hash",
			name: "Updated Torrent",
			state: .seeding,
			progress: 1.0,
			downloaded: 2048,
			uploaded: 1024,
			downloadRate: 500,
			uploadRate: 250,
			seedingTime: 3600
		)

		// Act
		originalTorrent.update(updatedTorrent)

		// Assert - All properties should be updated
		#expect(originalTorrent.hash == updatedTorrent.hash)
		#expect(originalTorrent.name == updatedTorrent.name)
		#expect(originalTorrent.state == updatedTorrent.state)
		#expect(originalTorrent.progress == updatedTorrent.progress)
		#expect(originalTorrent.downloaded == updatedTorrent.downloaded)
		#expect(originalTorrent.uploaded == updatedTorrent.uploaded)
		#expect(originalTorrent.downloadRate == updatedTorrent.downloadRate)
		#expect(originalTorrent.uploadRate == updatedTorrent.uploadRate)
		#expect(originalTorrent.dateAdded == updatedTorrent.dateAdded)
		#expect(originalTorrent.downloadPath == updatedTorrent.downloadPath)
		#expect(originalTorrent.eta == updatedTorrent.eta)
		#expect(originalTorrent.label == updatedTorrent.label)
		#expect(originalTorrent.peers == updatedTorrent.peers)
		#expect(originalTorrent.seeds == updatedTorrent.seeds)
		#expect(originalTorrent.seedingTime == updatedTorrent.seedingTime)
		#expect(originalTorrent.size == updatedTorrent.size)
		#expect(originalTorrent.totalPeers == updatedTorrent.totalPeers)
		#expect(originalTorrent.totalSeeds == updatedTorrent.totalSeeds)
		#expect(originalTorrent.trackers == updatedTorrent.trackers)
	}

	// MARK: - Computed Properties Tests

	@Test("StandardTorrent ratio calculation")
	func standardTorrentRatioCalculation() {
		// Test normal ratio calculation: uploaded / downloaded
		// This is the standard case where both values are positive
		let torrent1 = TestDataFactory.createStandardTorrent(
			downloaded: 500, uploaded: 1000
		)
		#expect(torrent1.ratio == 2.0)

		// Test edge case: zero downloaded bytes
		// This occurs when a torrent is added but hasn't started downloading yet
		// Mathematical result is infinity (division by zero)
		let torrent2 = TestDataFactory.createStandardTorrent(
			downloaded: 0, uploaded: 1000
		)
		#expect(torrent2.ratio.isInfinite)

		// Test edge case: zero uploaded bytes
		// This occurs when a torrent is downloading but hasn't uploaded anything yet
		// Result should be 0.0 (0 divided by any positive number)
		let torrent3 = TestDataFactory.createStandardTorrent(
			downloaded: 1000, uploaded: 0
		)
		#expect(torrent3.ratio == 0.0)

		// Test balanced ratio: equal upload and download
		// This represents a 1:1 sharing ratio, common target for private trackers
		let torrent4 = TestDataFactory.createStandardTorrent(
			downloaded: 1000, uploaded: 1000
		)
		#expect(torrent4.ratio == 1.0)
	}

	@Test("StandardTorrent isActive property", arguments: [
		(TorrentState.downloading, true),
		(TorrentState.seeding, true),
		(TorrentState.paused, false),
		(TorrentState.checking, false),
		(TorrentState.queued, false),
		(TorrentState.error, false)
	])
	func standardTorrentIsActiveProperty(state: TorrentState, expectedActive: Bool) {
		let torrent = TestDataFactory.createStandardTorrent(state: state)
		#expect(torrent.isActive == expectedActive)
	}

	@Test("StandardTorrent localizedSpeed for downloading state")
	func standardTorrentLocalizedSpeedDownloading() {
		let torrent = TestDataFactory.createStandardTorrent(
			state: .downloading,
			downloadRate: 1024 * 100, // 100 KB/s
			uploadRate: 1024 * 50      // 50 KB/s
		)

		// TODO: when this is localizable update it
		let localizedSpeed = torrent.localizedSpeed
		#expect(!localizedSpeed.isEmpty)
		// The exact format depends on L10n.Torrent.downloadUploadSpeed implementation
		// We just verify it's not empty for downloading state
	}

	@Test("StandardTorrent localizedSpeed for seeding state")
	func standardTorrentLocalizedSpeedSeeding() {
		let torrent = TestDataFactory.createStandardTorrent(
			state: .seeding,
			uploadRate: 1024 * 50 // 50 KB/s
		)

		// TODO: when this is localizable update it
		let localizedSpeed = torrent.localizedSpeed
		#expect(!localizedSpeed.isEmpty)
		// The exact format depends on L10n.Torrent.uploadSpeed implementation
		// We just verify it's not empty for seeding state
	}

	@Test("StandardTorrent localizedSpeed for non-active states")
	func standardTorrentLocalizedSpeedNonActive() {
		let states: [TorrentState] = [.paused, .checking, .queued, .error]

		for state in states {
			let torrent = TestDataFactory.createStandardTorrent(state: state)
			// TODO: when this is localizable update it
			#expect(torrent.localizedSpeed.isEmpty)
		}
	}

	@Test("StandardTorrent localizedProgress")
	func standardTorrentLocalizedProgress() {
		let torrent = TestDataFactory.createStandardTorrent(
			progress: 0.75,
			downloaded: 1024 * 1024 * 750, // 750 MB
			size: 1024 * 1024 * 1024       // 1 GB
		)

		// TODO: when this is localizable update it
		let localizedProgress = torrent.localizedProgress
		#expect(!localizedProgress.isEmpty)
		// The exact format depends on L10n.Torrent.progress implementation
		// We just verify it's not empty
	}

	@Test("StandardTorrent formattedETA with positive value")
	func standardTorrentFormattedETAPositive() {
		let torrent = TestDataFactory.createStandardTorrent(eta: 3600) // 1 hour
		let formattedETA = torrent.formattedETA
		// TODO: when this is localizable update it
		#expect(!formattedETA.isEmpty)
		// The exact format depends on Formatters.eta implementation
	}

	@Test("StandardTorrent formattedETA with zero or negative value")
	func standardTorrentFormattedETAZeroOrNegative() {
		let torrent1 = TestDataFactory.createStandardTorrent(eta: 0)
		let torrent2 = TestDataFactory.createStandardTorrent(eta: -1)

		// TODO: when this is localizable update it
		// Both should return infinity string (depends on L10n.Common.infinity)
		#expect(!torrent1.formattedETA.isEmpty)
		#expect(!torrent2.formattedETA.isEmpty)
	}

	@Test("StandardTorrent formattedRatio with normal values")
	func standardTorrentFormattedRatioNormal() {
		let torrent = TestDataFactory.createStandardTorrent(
			downloaded: 1000, uploaded: 1500
		)

		let formattedRatio = torrent.formattedRatio()
		#expect(!formattedRatio.isEmpty)

		// Test with custom precision
		let formattedRatioPrecision2 = torrent.formattedRatio(precision: 2)
		#expect(!formattedRatioPrecision2.isEmpty)
	}

	@Test("StandardTorrent formattedRatio with infinite ratio")
	func standardTorrentFormattedRatioInfinite() {
		let torrent = TestDataFactory.createStandardTorrent(
			downloaded: 0, uploaded: 1000 // This creates infinite ratio
		)

		// TODO: when this is localizable update it
		let formattedRatio = torrent.formattedRatio()
		#expect(!formattedRatio.isEmpty)
		// Should return infinity string (depends on L10n.Common.infinity)
	}

	@Test("StandardTorrent localizedRatioOrETA for downloading state")
	func standardTorrentLocalizedRatioOrETADownloading() {
		let torrent = TestDataFactory.createStandardTorrent(
			state: .downloading,
			eta: 3600
		)

		// TODO: when this is localizable update it
		let result = torrent.localizedRatioOrETA
		#expect(!result.isEmpty)
		// For downloading state, should return formatted ETA
	}

	@Test("StandardTorrent localizedRatioOrETA for non-downloading state")
	func standardTorrentLocalizedRatioOrETANonDownloading() {
		let torrent = TestDataFactory.createStandardTorrent(
			state: .seeding,
			downloaded: 1000, uploaded: 1500
		)

		// TODO: when this is localizable update it
		let result = torrent.localizedRatioOrETA
		#expect(!result.isEmpty)
		// For non-downloading state, should return formatted ratio
	}

	// MARK: - Equality and Hashing Tests

	@Test("StandardTorrent equality based on hash")
	func standardTorrentEquality() {
		let torrent1 = TestDataFactory.createStandardTorrent(
			hash: "same-hash",
			name: "Torrent 1",
			progress: 0.5
		)

		let torrent2 = TestDataFactory.createStandardTorrent(
			hash: "same-hash",
			name: "Torrent 2", // Different name
			progress: 0.8     // Different progress
		)

		let torrent3 = TestDataFactory.createStandardTorrent(
			hash: "different-hash",
			name: "Torrent 1"
		)

		// Torrents with same hash should be equal regardless of other properties
		#expect(torrent1 == torrent2)

		// Torrents with different hash should not be equal
		#expect(torrent1 != torrent3)
		#expect(torrent2 != torrent3)
	}

	@Test("StandardTorrent hashing consistency")
	func standardTorrentHashingConsistency() {
		let torrent1 = TestDataFactory.createStandardTorrent(
			hash: "test-hash",
			name: "Torrent 1"
		)

		let torrent2 = TestDataFactory.createStandardTorrent(
			hash: "test-hash",
			name: "Torrent 2" // Different name but same hash
		)

		// Objects that are equal should have the same hash value
		#expect(torrent1 == torrent2)
		#expect(torrent1.hashValue == torrent2.hashValue)

		// Test with Set to ensure hashing works correctly
		let torrentSet: Set<StandardTorrent> = [torrent1, torrent2]
		#expect(torrentSet.count == 1) // Should only contain one element due to same hash
	}

	// MARK: - Edge Cases Tests

	@Test("StandardTorrent with zero values")
	func standardTorrentZeroValues() {
		let torrent = TestDataFactory.createStandardTorrent(
			progress: 0,
			downloaded: 0,
			uploaded: 0,
			downloadRate: 0,
			uploadRate: 0,
			eta: 0
		)

		#expect(torrent.progress == 0)
		#expect(torrent.downloaded == 0)
		#expect(torrent.uploaded == 0)
		#expect(torrent.downloadRate == 0)
		#expect(torrent.uploadRate == 0)
		#expect(torrent.eta == 0)
		#expect(torrent.ratio.isNaN)
	}

	@Test("StandardTorrent with negative values")
	func standardTorrentNegativeValues() {
		let torrent = TestDataFactory.createStandardTorrent(
			downloaded: -100,
			uploaded: -50,
			downloadRate: -10,
			uploadRate: -5,
			eta: -1
		)

		// The model should accept negative values (validation might be elsewhere)
		#expect(torrent.downloaded == -100)
		#expect(torrent.uploaded == -50)
		#expect(torrent.downloadRate == -10)
		#expect(torrent.uploadRate == -5)
		#expect(torrent.eta == -1)
	}

	@Test("StandardTorrent with maximum values")
	func standardTorrentMaximumValues() {
		let torrent = TestDataFactory.createStandardTorrent(
			downloaded: Int64.max,
			uploaded: Int64.max,
			size: Int64.max
		)

		#expect(torrent.downloaded == Int64.max)
		#expect(torrent.uploaded == Int64.max)
		#expect(torrent.size == Int64.max)
		#expect(torrent.ratio == 1.0) // max/max = 1
	}

	@Test("StandardTorrent with Unicode characters")
	func standardTorrentUnicodeCharacters() {
		let unicodeName = "🎬 Test Movie [2024] 4K 🎥"
		let unicodeLabel = "🏷️ movies"
		let unicodePath = "/downloads/🎬 movies"

		let torrent = TestDataFactory.createStandardTorrent(
			name: unicodeName,
			label: unicodeLabel,
			downloadPath: unicodePath
		)

		#expect(torrent.name == unicodeName)
		#expect(torrent.label == unicodeLabel)
		#expect(torrent.downloadPath == unicodePath)
	}

	@Test("StandardTorrent Identifiable conformance")
	func standardTorrentIdentifiableConformance() {
		let hash = "test-identifiable-hash"
		let torrent = TestDataFactory.createStandardTorrent(hash: hash)

		// id should be the same as hash
		#expect(torrent.id == hash)
		#expect(torrent.id == torrent.hash)
	}
}
