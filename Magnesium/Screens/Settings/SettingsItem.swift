enum SettingsItem: Hashable, Equatable {
    case changeServer(String)
    case server(id: AnyHashable, name: String)
    case addServer
    case refreshInterval(current: String)
}
