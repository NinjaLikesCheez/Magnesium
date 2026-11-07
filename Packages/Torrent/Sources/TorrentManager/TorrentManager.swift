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

	private var updateTimer: Timer?

	/// Whether the app is in the foreground and allowed to auto-refresh.
	///
	/// When the app is backgrounded iOS suspends it and tears down open sockets. Firing refreshes while
	/// suspended (or reusing those dead keep-alive connections on resume) fails with
	/// `NSURLErrorNetworkConnectionLost`, so the timer only runs while active.
	@ObservationIgnored
	private var isActive = true

	/// Whether the auto-refresh timer is currently allowed to run.
	public var isAutoRefreshActive: Bool { isActive }

	/// Delay before retrying a refresh that failed with a transient connection error.
	@ObservationIgnored
	var transientRetryDelay: Duration = .milliseconds(500)

	public init(session: TorrentSessionProtocol, preferences: TorrentPreferences) {
		self.session = session
		self.preferences = preferences

		scheduleTimer(interval: preferences.autoRefreshInterval)

		let timerValue = Observations {
			preferences.autoRefreshInterval
		}

		Task { [weak self] in
			for await value in timerValue {
				guard let self else { return }
				self.scheduleTimer(interval: value)
			}
		}
	}

	/// Pauses or resumes auto-refresh to follow the app's lifecycle (e.g. SwiftUI `scenePhase`).
	public func setActive(_ active: Bool) {
		guard active != isActive else { return }
		isActive = active
		scheduleTimer(interval: preferences.autoRefreshInterval)
	}

	/// (Re)creates the auto-refresh timer. The timer only runs while the app is active and the interval is non-zero.
	private func scheduleTimer(interval: TimeInterval) {
		updateTimer?.invalidate()
		updateTimer = nil

		guard isActive, interval != 0 else { return }

		updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
			guard self != nil else {
				// The manager was deallocated; stop the run loop from firing forever.
				timer.invalidate()
				return
			}
			Task { @MainActor [weak self] in
				guard let self, self.isActive else { return }
				do {
					try await self.refresh()
				} catch {
					ErrorReporting.capture(error, feature: .client, operation: .autoRefresh)
				}
			}
		}
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

	public func verify(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		try await session.client.verify(torrents)
		try await refresh()
	}

	public func updateTrackers(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		try await session.client.updateTrackers(torrents)
		try await refresh()
	}

	public func paths(for torrent: StandardTorrent) async throws(TorrentClientError) -> [String] {
		try await session.client.paths(torrent)
	}

	public func refreshFiles(for torrent: StandardTorrent) async throws(TorrentClientError) -> [StandardTorrentFile] {
		try await session.client.refreshFiles(torrent)
	}

	public func refresh() async throws(TorrentClientError) {
		guard session.server != nil else { return }
		let (torrents, labels) = try await fetchWithTransientRetry()

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

	/// Fetches torrents, retrying once if the connection was dropped (e.g. a keep-alive socket torn down while
	/// the app was suspended). Any other error, or a second failure, is rethrown to the caller for reporting.
	private func fetchWithTransientRetry() async throws(TorrentClientError) -> ([StandardTorrent], [StandardLabel]) {
		do throws(TorrentClientError) {
			return try await session.client.refresh()
		} catch where error.isTransientConnectionError {
			try? await Task.sleep(for: transientRetryDelay)
			return try await session.client.refresh()
		}
	}
}

extension TorrentClientError {
	/// Connection-level failures that are expected to succeed on an immediate retry.
	var isTransientConnectionError: Bool {
		guard case .deluge(.request(.urlError(let urlError))) = self else { return false }
		switch urlError.code {
		case .networkConnectionLost, .timedOut:
			return true
		default:
			return false
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
