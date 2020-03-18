protocol StandardLabel {
    var name: String { get }
    var count: Int { get }
}

extension StandardLabel {
    var displayName: String {
        name.isEmpty ? L10n.noneLabel : name
    }
}

extension Never: StandardLabel {
    var name: String {
        ""
    }

    var count: Int {
        0
    }
}
