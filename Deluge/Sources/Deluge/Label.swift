/// A Deluge label.
public struct Label {
    /// The label name.
    public var name: String
    /// The number of torrents with this label.
    public var count: Int

    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }
}
