/// A Transmission tracker.
public struct Tracker: Equatable {
    /// The tracker's ID.
    public let id: Int
    /// The tracker host URL.
    public let host: String

    /// Creates a `Tracker` with the given parameters.
    public init(id: Int, host: String) {
        self.id = id
        self.host = host
    }
}

extension Tracker {
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? Int,
            let host = dictionary["host"] as? String
        else {
            return nil
        }

        self.id = id
        self.host = host
    }
}
