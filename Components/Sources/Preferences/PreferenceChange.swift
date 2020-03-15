/// Types of preference changes that can occur.
public enum PreferenceChange {
    /// A preference was updated.
    case updated(AnyPreferenceKey, Any)
    /// A preference value was deleted.
    case deleted(AnyPreferenceKey)
    /// All preferences were reset to their default values.
    case reset

    /// Returns whether the change affects the given preference key.
    /// - Parameter key: The preference key to check.
    public func isRelevant<T>(to key: PreferenceKey<T>) -> Bool {
        switch self {
        case let .updated(changedKey, _):
            return key.value == changedKey.value
        case let .deleted(changedKey):
            return key.value == changedKey.value
        case .reset:
            return true
        }
    }
}
