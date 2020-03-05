/// A Deluge torrent tracker.
public struct Tracker {
    /// The tracker URL.
    public var url: String

    /// Creates a `Tracker` with the given parameters.
    public init(url: String) {
        self.url = url
    }
}

extension Tracker {
    /// Creates a `Tracker` from a response dictionary, returning nil if any required properties are missing.
    /// - Parameters:
    ///   - dictionary: The response dictionary for the tracker.
    init?(dictionary: [String: Any]) {
        guard let url = dictionary["url"] as? String else { return nil }
        self.url = url
    }
}
