//
//  TorrentManager.swift
//  Magnesium
//
//  Created by ninji on 11/06/2025.
//
import Common
import Observation
import SwiftUI

@MainActor
@Observable
public final class TorrentManager {
	public typealias Hash = String

	private(set) public var torrents: [Hash: StandardTorrent] = [:]
	private(set) public var labels: [StandardLabel] = []

	public var searchQuery: String = ""

	@ObservationIgnored
	private let session: TorrentSessionProtocol

	@ObservationIgnored
	private let preferences: TorrentPreferences

	@ObservationIgnored
	private let scheduling: TorrentScheduling

	@ObservationIgnored
	private var observationTask: Task<Void, Never>?

	private var updateTimer: Cancellable?

	public init(
		session: TorrentSessionProtocol,
		preferences: TorrentPreferences,
		scheduling: TorrentScheduling = LiveTorrentScheduler()
	) {
		self.session = session
		self.preferences = preferences
		self.scheduling = scheduling

		// `Observations` yields the current value immediately on first await (after the current
		// synchronous call stack completes), then again on each subsequent change. This means the
		// initial schedule happens asynchronously, not during init — tests must await to observe it.
		let timerValue = Observations {
			preferences.autoRefreshInterval
		}

		observationTask = Task { [weak self] in
			for await value in timerValue {
				guard let self else { return }

				self.updateTimer?.invalidate()
				self.updateTimer = nil

				if value != 0 {
					self.updateTimer = scheduling.schedule(interval: value) { [weak self] in
						Task { try await self?.refresh() }
					}
				}
			}
		}
	}

	isolated deinit {
		observationTask?.cancel()
		updateTimer?.invalidate()
	}

	public func resume(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		try await session.client.resume(torrents)
		try await refresh()
	}

	public func pause(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		try await session.client.pause(torrents)
		try await refresh()
	}

	public func delete(_ torrents: [StandardTorrent], removeData: Bool) async throws(TorrentClientError) {
		try await session.client.remove(torrents, removeData)
		try await refresh()
	}

	public func addLink(_ link: String) async throws(TorrentClientError) {
		try await session.client.addLink(link)
		try await refresh()
	}

	public func paths(for torrent: StandardTorrent) async throws(TorrentClientError) -> [String] {
		try await session.client.paths(torrent)
	}

	public func refreshFiles(for torrent: StandardTorrent) async throws(TorrentClientError) -> [StandardTorrentFile] {
		try await session.client.refreshFiles(torrent)
	}

	public func refresh() async throws(TorrentClientError) {
		let (torrents, labels) = try await session.client.refresh()

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
	public var filteredTorrents: [StandardTorrent] {
		TorrentMapper.map(
			torrents.map(\.value),
			query: searchQuery,
			sortOption: preferences.sortOption,
			filterOptions: preferences.filterOptions
		)
	}

	public var totalUploadSpeed: String {
		torrents
			.values
			.reduce(into: 0) { $0 += $1.uploadRate }
			.formatted(Formatters.bytes)
	}

	public var totalDownloadSpeed: String {
		torrents
			.values
			.reduce(into: 0) { $0 += $1.downloadRate }
			.formatted(Formatters.bytes)
	}
}
