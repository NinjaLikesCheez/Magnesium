import Foundation

protocol StandardLabel {
    var name: String { get }
    var count: Int { get }
}

extension StandardLabel {
    var displayName: String {
        return name.isEmpty ? L10n.noneLabel : name
    }
}
