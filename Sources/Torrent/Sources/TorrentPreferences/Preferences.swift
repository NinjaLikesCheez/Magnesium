import Foundation

/*
* TODO: this needs to be refactored to have like a generic preferences container, and then each module
* can provide additional preferences for their specific implementation details
*/
public protocol Preferences: AnyObject {
	var autoRefreshInterval: TimeInterval { get set }
	var servers: [TorrentServer] { get set }
	var selectedServerID: String? { get set }
	var sortOption: TorrentSortOption { get set }
	var filterOptions: TorrentFilterOptions { get set }
	var automaticallyLookForMagnetLinks: Bool { get set }

	func getSelectedServer() throws -> TorrentServer?
	func remove(server: TorrentServer) throws
	func removeServers() throws
	func reset()
}
