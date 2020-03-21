enum SettingsItem {
    case changeServer(String)
    case server(id: AnyHashable, name: String)
    case addServer
    case refreshInterval(current: String)
}

extension SettingsItem: Equatable {}
extension SettingsItem: Hashable {}
