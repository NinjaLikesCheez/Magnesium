/// A preference key with no associted type.
public struct AnyPreferenceKey {
    /// The key's string value.
    public let value: String

    init(_ value: String) {
        self.value = value
    }
}
