//
//  TorrentListRouter.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//

import Observation
import Router

/// Handles navigation within the main torrent list screen
@Observable
final class TorrentListRouter: RouterProtocol {
	typealias Destination = TorrentListDestination
	typealias Sheet = TorrentListSheet
	typealias Error = TorrentListError

	var path: [Destination] = []
	var presentedSheet: Sheet? = nil
	var presentedError: Error? = nil
	let parent: (any RouterProtocol)?

	required init(_ parent: (any RouterProtocol)? = nil) {
		self.parent = parent
	}
}
