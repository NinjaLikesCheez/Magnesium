//
//  TorrentManager.swift
//  Magnesium
//
//  Created by ninji on 11/06/2025.
//
import Observation
import SwiftUI

@MainActor
@Observable
final class TorrentManager {
	typealias Hash = String

	private(set) var torrents: [Hash: StandardTorrent] = [:]
	private(set) var labels: [StandardLabel] = []

	var searchQuery: String = ""

	@ObservationIgnored
	private let session: SessionProtocol

	@ObservationIgnored
	private let preferences: Preferences

	private var updateTimer: Timer!

	init(session: SessionProtocol, preferences: Preferences) {
		self.session = session
		self.preferences = preferences

		self.updateTimer = Timer.scheduledTimer(
			withTimeInterval: preferences.autoRefreshInterval, repeats: true,
			block: { [weak self] _ in
				guard let self else { return }
				Task { try await self.refresh() }
			})

		withObservationTracking(of: preferences.autoRefreshInterval) { interval in
			// if we don't invalidate here, the timers will remain on the old interval (idk why)
			self.updateTimer.invalidate()
			self.updateTimer = Timer.scheduledTimer(
				withTimeInterval: interval, repeats: true,
				block: { [weak self] _ in
					guard let self else { return }
					Task { try await self.refresh() }
				})
		}
	}

	func resume(_ torrents: [StandardTorrent]) async throws {
		try await session.actionImplementation.resume(torrents)
		try await refresh()
	}

	func pause(_ torrents: [StandardTorrent]) async throws {
		try await session.actionImplementation.pause(torrents)
		try await refresh()
	}

	func delete(_ torrents: [StandardTorrent], removeData: Bool) async throws {
		try await session.actionImplementation.remove(torrents, removeData)
		try await refresh()
	}

	func addLink(_ link: String) async throws {
		try await session.actionImplementation.addLink(link)
		try await refresh()
	}

	func paths(for torrent: StandardTorrent) async throws -> [String] {
		try await session.actionImplementation.paths(torrent)
	}

	func refreshFiles(for torrent: StandardTorrent) async throws -> [StandardTorrentFile] {
		try await session.actionImplementation.refreshFiles(torrent)
	}

	nonisolated func refresh() async throws(TorrentClientError) {
		let (torrents, labels) = try await session.actionImplementation.refresh()

		// We have to do 'delta' style updates so the view bindings work properly.
		// First, calculate the changes in torrents

		await MainActor.run {
			var torrentsCopy = self.torrents
			let updatedTorrents = torrents.reduce(into: [String: StandardTorrent](), { $0[$1.hash] = $1 })
			let hashDifference = updatedTorrents.map(\.key).difference(from: torrentsCopy.map(\.key)).inferringMoves()

			for change in hashDifference.removals {
				switch change {
				case .remove(offset: _, element: let hash, associatedWith: let associatedWith):
					if associatedWith == nil {
						torrentsCopy.removeValue(forKey: hash)
					}
				default:
					continue
				}
			}

			for (hash, element) in updatedTorrents {
				if let torrent = torrentsCopy[hash] {
					torrent.update(element)
				}
			}

			for change in hashDifference.insertions {
				switch change {
				case .insert(offset: _, element: let hash, associatedWith: let associatedWith):
					if associatedWith == nil {
						torrentsCopy[hash] = updatedTorrents[hash]
					}
				default:
					continue
				}
			}

			self.torrents = torrentsCopy
			self.labels = labels.sorted(by: { $0.name < $1.name })
		}
	}
}

extension TorrentManager {
	var filteredTorrents: [StandardTorrent] {
		TorrentMapper.map(
			torrents.map(\.value),
			query: searchQuery,
			sortOption: preferences.sortOption,
			filterOptions: preferences.filterOptions
		)
	}

	var totalUploadSpeed: String {
		torrents
			.values
			.reduce(into: 0) { $0 += $1.uploadRate }
			.formatted(Formatters.bytes)
	}

	var totalDownloadSpeed: String {
		torrents
			.values
			.reduce(into: 0) { $0 += $1.downloadRate }
			.formatted(Formatters.bytes)
	}
}
