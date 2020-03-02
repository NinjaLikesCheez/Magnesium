/// A strongly typed preference key.
public struct PreferenceKey<T: Codable> {
    /// The key's string value.
    public let value: String
    /// The key's default value
    public let defaultValue: T

    /// Creates a `PreferenceKey` with the given string value.
    /// - Parameters:
    ///   - value: The string value of the key.
    ///   - defaultValue: The default value for the preference.
    public init(_ value: String, defaultValue: T) {
        self.value = value
        self.defaultValue = defaultValue
    }
}
