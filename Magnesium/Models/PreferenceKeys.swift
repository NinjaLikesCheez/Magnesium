import Preferences

enum PreferenceKeys {
    static let autoRefreshInterval = PreferenceKey<Int>("autoRefreshInterval", defaultValue: 2)
    static let servers = PreferenceKey<[Server]>("servers", defaultValue: [])
    static let selectedServerID = PreferenceKey<Server.ID?>("selectedServerID", defaultValue: nil)
    static let sortOption = PreferenceKey<SortOption>("sortOption", defaultValue: SortOption(property: .dateAdded))
    static let filterOptions = PreferenceKey<FilterOptions>("filterOptions", defaultValue: FilterOptions())
}
