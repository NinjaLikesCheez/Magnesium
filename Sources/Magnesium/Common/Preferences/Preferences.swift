import Foundation

protocol Preferences: AnyObject {
	var autoRefreshInterval: TimeInterval { get set }
	var servers: [Server] { get set }
	var selectedServerID: String? { get set }
	var sortOption: SortOption { get set }
	var filterOptions: FilterOptions { get set }
	var automaticallyLookForMagnetLinks: Bool { get set }

	func getSelectedServer() throws -> Server?
	func remove(server: Server) throws
	func removeServers() throws
	func reset()
}
