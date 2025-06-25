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

	@ObservationIgnored
	private let session: Session

	init(session: Session) {
		self.session = session
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

	nonisolated func refresh() async throws {
		let (torrents, labels) = try await session.actionImplementation.refresh()

		await MainActor.run {
			self.torrents = torrents
			self.labels = labels
		}
	}
}
