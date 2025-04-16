import Combine

/// A preferences implementation that stores values in memory.
public final class InMemoryPreferences: Preferences {
	private let store = [String: Any]()

	public var servers: [Server] = []

	public var selectedServerID: String?

	public var sortOption: SortOption

	public var filterOptions: FilterOptions

	public var automaticallyLookForMagnetLinks: Bool
}

public extension InMemoryPreferences {
    /// A container to store values in a dictionary.
    final class Store {
        /// The stored values.
        public var values = [AnyPreferenceKey: Any]()

        /// Creates a new in-memory preferences store.
        public init() {}

        func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
            values.keys.contains(AnyPreferenceKey(key))
        }

        func removeValue<T>(for key: PreferenceKey<T>) {
            values.removeValue(forKey: AnyPreferenceKey(key))
        }

        func removeAll() {
            values.removeAll()
        }

        /// The subscript accessor for stored values.
        subscript<T>(key: PreferenceKey<T>) -> T {
            get { values[AnyPreferenceKey(key)] as? T ?? key.defaultValue }
            set { values[AnyPreferenceKey(key)] = newValue }
        }
    }
}
