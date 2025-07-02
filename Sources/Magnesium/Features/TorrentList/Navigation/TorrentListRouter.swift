//
//  TorrentListRouter.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//

import Observation

/// Router for the TorrentList feature flow.
/// 
/// Handles navigation within the main torrent list screen, providing:
/// - Push navigation to torrent detail views
/// - Modal presentation of settings and other sheets
/// 
/// **Destinations:**
/// - `.detail(StandardTorrent)`: Navigate to detailed view of a specific torrent
/// 
/// **Sheets:**
/// - `.settings`: Present the settings modal
/// 
/// **Usage:**
/// ```swift
/// @Environment(TorrentListRouter.self) private var router
/// 
/// // Navigate to torrent detail
/// router.push(.detail(selectedTorrent))
/// 
/// // Present settings sheet
/// router.presentSheet(.settings)
/// ```
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
