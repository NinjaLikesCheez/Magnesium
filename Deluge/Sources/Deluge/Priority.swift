/// A priority value for Deluge downloads.
public struct Priority: RawRepresentable, Equatable, Hashable {
    public static let low = Priority(1)
    public static let normal = Priority(4)
    public static let high = Priority(7)

    public typealias RawValue = Int

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}
