/// A representation of a preference change.
public struct PreferenceChange {
    /// The preference key that was changed.
    public let key: AnyPreferenceKey
    /// The type of change that occurred.
    public let type: PreferenceChangeType

    /// Creates a new `PreferenceChange` with the given parameters.
    /// - Parameters:
    ///   - key: The preference key.
    ///   - type: The change type.
    public init(key: AnyPreferenceKey, type: PreferenceChangeType) {
        self.key = key
        self.type = type
    }
}

/// Types of preference changes that can occur.
public enum PreferenceChangeType {
    /// The preference was updated.
    case updated(Any)
    /// The preference value was
    case deleted
}
