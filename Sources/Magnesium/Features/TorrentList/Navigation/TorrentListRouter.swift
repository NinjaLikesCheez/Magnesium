//
//  TorrentListRouter.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//

import Observation

/// Router for the TorrentList feature flow.
/// 
/// Handles navigation within the main torrent list screen for viewing
/// torrent details and accessing application settings.
@Observable
final class TorrentListRouter: RouterProtocol {
	typealias Destination = TorrentListDestination
	typealias Sheet = TorrentListSheet

	var path: [TorrentListDestination] = []
	var presentedSheet: TorrentListSheet? = nil
	let parent: (any RouterProtocol)?

	required init(_ parent: (any RouterProtocol)? = nil) {
		self.parent = parent
	}
}
