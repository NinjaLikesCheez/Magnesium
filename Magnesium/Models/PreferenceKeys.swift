import Preferences

extension PreferenceKey where T == Int {
    static let autoRefreshInterval = PreferenceKey<Int>("autoRefreshInterval", defaultValue: 2)
}

extension PreferenceKey where T == [Server] {
    static let servers = PreferenceKey<[Server]>("servers", defaultValue: [])
}

extension PreferenceKey where T == Server.ID? {
    static let selectedServerID = PreferenceKey<Server.ID?>("selectedServerID", defaultValue: nil)
}

extension PreferenceKey where T == SortOption {
    static let sortOption = PreferenceKey<SortOption>("sortOption", defaultValue: SortOption(property: .dateAdded))
}

extension PreferenceKey where T == FilterOptions {
    static let filterOptions = PreferenceKey<FilterOptions>("filterOptions", defaultValue: FilterOptions())
}
