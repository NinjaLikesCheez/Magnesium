import Foundation
import Observation


extension PreferenceKey {
	static var autoRefreshInterval: PreferenceKey<TimeInterval> {
		.init("autoRefreshInterval", defaultValue: 2)
	}

	static var servers: PreferenceKey<[Server]> {
		.init("servers", defaultValue: [])
	}

	static var selectedServerID: PreferenceKey<String?> {
		.init("selectedServerID", defaultValue: nil)
	}

	static var sortOption: PreferenceKey<SortOption> {
		.init("sortOption", defaultValue: SortOption(property: .dateAdded))
	}

	static var filterOptions: PreferenceKey<FilterOptions> {
		.init("filterOptions", defaultValue: FilterOptions())
	}

	static var automaticallyLookForMagnetLinks: PreferenceKey<Bool> {
		.init("automaticallyLookForMagnetLinks", defaultValue: false)
	}
}
