/// A preference key with no associated type.
public struct AnyPreferenceKey {
    /// The key's string value.
    public let value: String

    /// Creates a new `AnyPreferenceKey` with the given string value.
    /// - Parameter value: The string value of the key.
    public init(_ value: String) {
        self.value = value
    }
}
