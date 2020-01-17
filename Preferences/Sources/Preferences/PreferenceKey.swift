/// A strongly typed preference key.
public struct PreferenceKey<T: Codable> {
    /// The key's string value.
    public let value: String

    /// Creates a new `PreferenceKey` with the given string value.
    /// - Parameter value: The string value of the key.
    public init(_ value: String) {
        self.value = value
    }
}
