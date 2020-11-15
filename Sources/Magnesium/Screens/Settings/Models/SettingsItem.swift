enum SettingsItem: Equatable, Hashable {
    case changeServer(String)
    case server(id: AnyHashable, name: String)
    case addServer
    case refreshInterval(current: String)
}
