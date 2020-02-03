/// A Transmission tracker.
public struct Tracker {
    /// The tracker's ID.
    public let id: Int
    /// The tracker's host.
    public let host: String

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
