import Foundation
@testable import Magnesium

/// Factory for creating test data objects with configurable properties
struct TestDataFactory {

	// MARK: - StandardTorrent Factory Methods

	static func createStandardTorrent(
		hash: String = "test-torrent-hash",
		name: String = "Test Torrent",
		state: TorrentState = .downloading,
		progress: Float = 0.5,
		downloaded: Int64 = 1024 * 1024 * 500, // 500 MB
		uploaded: Int64 = 1024 * 1024 * 250,   // 250 MB
		size: Int64 = 1024 * 1024 * 1024,      // 1 GB
		downloadRate: Int64 = 1024 * 100,      // 100 KB/s
		uploadRate: Int64 = 1024 * 50,         // 50 KB/s
		eta: TimeInterval = 3600,              // 1 hour
		dateAdded: Date = Date(),
		label: String = "test-label",
		downloadPath: String = "/downloads",
		peers: Int = 5,
		seeds: Int = 10,
		seedingTime: TimeInterval = 0,
		totalPeers: Int = 20,
		totalSeeds: Int = 30,
		trackers: [String] = ["http://tracker.example.com"]
	) -> StandardTorrent {
		return StandardTorrent(
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
	}

	static func createMultipleTorrents(count: Int) -> [StandardTorrent] {
		return (0..<count).map { index in
			createStandardTorrent(
				hash: "torrent-hash-\(UUID().uuidString)",
				name: "Test Torrent \(index)",
				state: TorrentState.allCases.randomElement() ?? .downloading,
				progress: Float.random(in: 0...1),
				downloaded: Int64.random(in: 0...1024*1024*1024),
				uploaded: Int64.random(in: 0...1024*1024*500)
			)
		}
	}

	// MARK: - Server Factory Methods

	static func createServer(
		name: String = "Test Server",
		type: ServerType = .deluge,
		data: Data = .init(#"{ "url": "http://localhost:8112" }"#.data(using: .utf8)!),
		keychainData: Data? = .init(#"{ "password": "test" }"#.data(using: .utf8)!)
	) -> Server {
		return Server(name: name, type: type, data: data, keychainData: keychainData)
	}

	static func createMultipleServers(count: Int) -> [Server] {
		return (0..<count).map { index in
			createServer(
				name: "Test Server \(index)",
				type: .deluge,
				data: .init(#"{ "url": "http://localhost:8112" }"#.data(using: .utf8)!),
				keychainData: .init(#"{ "password": "test" }"#.data(using: .utf8)!)
			)
		}
	}

	// MARK: - StandardLabel Factory Methods

	static func createStandardLabel(
		name: String = "test-label",
		count: Int? = 5
	) -> StandardLabel {
		return StandardLabel(name: name, count: count)
	}

	static func createMultipleLabels(count: Int) -> [StandardLabel] {
		return (0..<count).map { index in
			createStandardLabel(
				name: "label-\(index)",
				count: Int.random(in: 0...20)
			)
		}
	}

	// MARK: - StandardTorrentFile Factory Methods

	static func createStandardTorrentFile(
		index: Int = 0,
		name: String = "test-file.txt",
		size: Int64 = 1024 * 1024, // 1 MB
		progress: Float = 0.5,
		priority: TorrentPriority = .normal
	) -> StandardTorrentFile {
		return StandardTorrentFile(
			index: index,
			name: name,
			size: size,
			progress: progress,
			priority: priority
		)
	}

	static func createMultipleTorrentFiles(count: Int) -> [StandardTorrentFile] {
		return (0..<count).map { index in
			createStandardTorrentFile(
				index: index,
				name: "file-\(index).txt",
				size: Int64.random(in: 1024...1024*1024*100), // 1KB to 100MB
				progress: Float.random(in: 0...1),
				priority: TorrentPriority.allCases.randomElement() ?? .normal
			)
		}
	}
}

// MARK: - Extensions for Test Data Variations

extension TestDataFactory {

	/// Creates torrents with specific states for testing filtering
	static func createTorrentsWithStates(_ states: [TorrentState]) -> [StandardTorrent] {
		return states.enumerated().map { index, state in
			createStandardTorrent(
				hash: "torrent-hash-\(index)",
				name: "Torrent \(state.rawValue)",
				state: state
			)
		}
	}

	/// Creates torrents with specific labels for testing filtering
	static func createTorrentsWithLabels(_ labels: [String]) -> [StandardTorrent] {
		return labels.enumerated().map { index, label in
			createStandardTorrent(
				hash: "torrent-hash-\(index)",
				name: "Torrent with \(label)",
				label: label
			)
		}
	}

	/// Creates torrents with edge case values for testing
	static func createEdgeCaseTorrents() -> [StandardTorrent] {
		return [
			// Zero values
			createStandardTorrent(
				hash: "zero-torrent-hash",
				name: "Zero Values Torrent",
				progress: 0,
				downloaded: 0,
				uploaded: 0,
				downloadRate: 0,
				uploadRate: 0
			),
			// Complete torrent
			createStandardTorrent(
				hash: "complete-torrent-hash",
				name: "Complete Torrent",
				state: .seeding,
				progress: 1.0
			),
			// Large values
			createStandardTorrent(
				hash: "large-torrent-hash",
				name: "Large Torrent",
				downloaded: Int64.max / 2,
				uploaded: Int64.max / 4,
				size: Int64.max / 2
			),
			// Unicode name
			createStandardTorrent(
				hash: "unicode-torrent-hash",
				name: "🎬 Test Movie [2024] 4K 🎥",
				label: "🏷️ movies"
			)
		]
	}
}
