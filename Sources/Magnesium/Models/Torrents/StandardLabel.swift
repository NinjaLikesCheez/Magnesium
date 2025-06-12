struct StandardLabel: Equatable, Identifiable {
	var id: String { name }
	var name: String
	var count: Int?
}

extension StandardLabel {
	var displayName: String {
		name.isEmpty ? L10n.Label.none : name
	}
}

extension StandardLabel: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(count)
	}
}
