/// A Transmission tracker.
public struct Tracker {
    /// The tracker's ID.
    public let id: Int
    /// The tracker's host.
    public let host: String
    /// The current number of seeders.
    public let seeders: Int

    public init(id: Int, host: String, seeders: Int) {
        self.id = id
        self.host = host
        self.seeders = seeders
    }
}

extension Tracker {
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? Int,
            let host = dictionary["host"] as? String,
            let seeders = dictionary["seederCount"] as? Int
        else {
            return nil
        }

        self.id = id
        self.host = host
        self.seeders = seeders
    }
}
