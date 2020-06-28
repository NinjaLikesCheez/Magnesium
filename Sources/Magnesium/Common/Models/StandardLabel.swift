struct StandardLabel {
    var name: String
    var count: Int
}

extension StandardLabel: Equatable {}

extension StandardLabel {
    var displayName: String {
        name.isEmpty ? L10n.Label.none : name
    }
}
