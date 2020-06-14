enum SettingsSectionType {
    case changeServer
    case servers
    case general
}

extension SettingsSectionType: Equatable {}
extension SettingsSectionType: Hashable {}
