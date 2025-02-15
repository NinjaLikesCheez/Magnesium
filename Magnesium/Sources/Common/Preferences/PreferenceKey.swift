/// A key that uniquely identifies a preference.
public struct PreferenceKey<T: Codable> {
    /// The unique identifier used for storage.
    public let identifier: String
    /// The default value of the preference.
    public let defaultValue: T

    /// Initializes a preference key.
    /// - Parameters:
    ///   - identifier: The unique identifier used for storage.
    ///   - defaultValue: The default value of the preference.
    public init(_ identifier: String, defaultValue: T) {
        self.identifier = identifier
        self.defaultValue = defaultValue
    }
}

extension PreferenceKey: Equatable {
    public static func == (lhs: PreferenceKey<T>, rhs: PreferenceKey<T>) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

extension PreferenceKey: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
