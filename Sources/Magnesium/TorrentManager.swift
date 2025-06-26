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
	// TODO: migrate all uses of the session's actionImplementation to this class
	private(set) var torrents: [StandardTorrent] = []
	private(set) var labels: [StandardLabel] = []

	var searchQuery: String = ""

	@ObservationIgnored
	private let session: Session

	@ObservationIgnored
	private let preferences: AppPreferences

	init(session: Session, preferences: AppPreferences) {
		self.session = session
		self.preferences = preferences
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

	nonisolated func refresh() async throws {
		let (torrents, labels) = try await session.actionImplementation.refresh()

		await MainActor.run {
			self.torrents = torrents
			self.labels = labels
		}
	}
}

extension TorrentManager {
	var filteredTorrents: [StandardTorrent] {
		TorrentMapper.map(
			torrents,
			query: searchQuery,
			sortOption: preferences.sortOption,
			filterOptions: preferences.filterOptions
		)
	}

	var totalUploadSpeed: String {
		Formatters.bytes.string(
			fromByteCount: torrents.reduce(into: 0) { $0 += $1.uploadRate }
		)
	}

	var totalDownloadSpeed: String {
		Formatters.bytes.string(
			fromByteCount: torrents.reduce(into: 0) { $0 += $1.downloadRate }
		)
	}
}
