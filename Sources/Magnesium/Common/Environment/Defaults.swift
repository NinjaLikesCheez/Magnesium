struct Defaults {
    var autoRefreshInterval: Int
}

extension Defaults {
    static let live = Defaults(autoRefreshInterval: 2)
}
