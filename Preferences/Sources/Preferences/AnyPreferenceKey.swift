/// A preference key with no associated type.
public struct AnyPreferenceKey {
    /// The key's string value.
    public let value: String

    /// Creates a new `AnyPreferenceKey` using the string value of the given preference key.
    /// - Parameter key: The preference key to type erase.
    public init<T>(_ key: PreferenceKey<T>) {
        value = key.value
    }
}
