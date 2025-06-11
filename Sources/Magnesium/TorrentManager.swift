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
	private(set) var torrents: [StandardTorrent] = []
	private(set) var labels: [StandardLabel] = []

	@ObservationIgnored
	private let session: Session

	init(session: Session) {
		self.session = session
	}

	nonisolated func refresh() async throws {
		let (torrents, labels) = try await session.actionImplementation.refresh()

		await MainActor.run {
			self.torrents = torrents
			self.labels = labels
		}
	}
}
