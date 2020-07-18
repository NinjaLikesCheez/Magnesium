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
        self // This only works as self in iOS 14b2
    }
}
