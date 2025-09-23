public struct StandardLabel: Equatable, Identifiable {
	public var id: String { name }
	public var name: String
	public var count: Int?

	public init(name: String, count: Int?) {
		self.name = name
		self.count = count
	}
}

extension StandardLabel {
	public var displayName: String {
		name.isEmpty ? "None" : name
	}
}

extension StandardLabel: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(count)
	}
}
