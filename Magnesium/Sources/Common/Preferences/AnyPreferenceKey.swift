/// A preference key with no associated type.
public struct AnyPreferenceKey: Equatable, Hashable {
    /// The unique identifier used for storage.
    public let identifier: String

    /// Creates a type-erased preference key using the value of the given preference key.
    /// - Parameter key: The preference key to type erase.
    public init<T>(_ key: PreferenceKey<T>) {
        identifier = key.identifier
    }
}
