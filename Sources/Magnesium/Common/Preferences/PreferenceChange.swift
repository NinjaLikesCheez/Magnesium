/// Types of preference changes that can occur.
public enum PreferenceChange {
    /// A preference was updated.
    case updated(AnyPreferenceKey, Any)
    /// A preference was deleted.
    case deleted(AnyPreferenceKey)
    /// All preferences were reset to their default values.
    case reset

    /// Returns whether the change affects the given key.
    /// - Parameter key: A key uniquely identifying the preference.
    public func isRelevant<T>(to key: PreferenceKey<T>) -> Bool {
        switch self {
        case let .updated(changedKey, _):
            return key.identifier == changedKey.identifier
        case let .deleted(changedKey):
            return key.identifier == changedKey.identifier
        case .reset:
            return true
        }
    }
}
