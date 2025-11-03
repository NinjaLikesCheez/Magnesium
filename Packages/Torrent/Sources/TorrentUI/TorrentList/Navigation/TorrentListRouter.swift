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
public final class TorrentListRouter: Routable {
	public typealias Destination = TorrentListDestination
	public typealias Sheet = TorrentListSheet
	public typealias Error = TorrentListError

	public var path: [Destination] = []
	public var presentedSheet: Sheet? = nil
	public var presentedError: Error? = nil
	public let parent: (any Routable)?

	public required init(_ parent: (any Routable)? = nil) {
		self.parent = parent
	}
}
