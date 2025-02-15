extension PreferenceKey {
	static var autoRefreshInterval: PreferenceKey<Int> {
		.init("autoRefreshInterval", defaultValue: 2)  // TODO: Migrate this to a 'defaults' thing like old Magnesium
	}

	static var servers: PreferenceKey<[Server]> {
		.init("servers", defaultValue: [])
	}

	static var selectedServerID: PreferenceKey<String?> {
		.init("selectedServerID", defaultValue: nil)
	}

	// static var sortOption: PreferenceKey<SortOption> {
	// 	.init("sortOption", defaultValue: SortOption(property: .dateAdded))
	// }

	// static var filterOptions: PreferenceKey<FilterOptions> {
	// 	.init("filterOptions", defaultValue: FilterOptions())
	// }
}
