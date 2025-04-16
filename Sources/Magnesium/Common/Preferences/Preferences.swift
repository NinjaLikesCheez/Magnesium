import Foundation

protocol Preferences {
	var autoRefreshInterval: TimeInterval { get set }
	var servers: [Server] { get set }
	var selectedServerID: String? { get set }
	var sortOption: SortOption { get set }
	var filterOptions: FilterOptions { get set }
	var automaticallyLookForMagnetLinks: Bool { get set }
}
