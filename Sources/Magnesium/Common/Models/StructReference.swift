import Foundation

final class StructReference<Value>: RawRepresentable, NSCopying {
    let rawValue: Value

    init(_ rawValue: Value) {
        self.rawValue = rawValue
    }

    init?(rawValue: Value) {
        self.rawValue = rawValue
    }

    func copy(with zone: NSZone? = nil) -> Any {
        StructReference(rawValue)
    }
}
