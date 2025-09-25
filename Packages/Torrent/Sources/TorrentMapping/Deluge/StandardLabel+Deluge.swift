import Deluge

public extension StandardLabel {
	init(_ label: Label) {
		self.init(name: label.name, count: label.count)
	}
}
