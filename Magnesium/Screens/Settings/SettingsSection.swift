struct SettingsSection {
    let type: SettingsSectionType
    let items: [SettingsItem]
}

extension SettingsSection: Equatable {}
extension SettingsSection: Hashable {}
