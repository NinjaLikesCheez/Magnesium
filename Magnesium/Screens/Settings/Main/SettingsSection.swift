struct SettingsSection: Equatable {
    enum SectionType: Hashable {
        case changeServer
        case servers
        case general
    }

    let type: SectionType
    let items: [SettingsItem]
}
