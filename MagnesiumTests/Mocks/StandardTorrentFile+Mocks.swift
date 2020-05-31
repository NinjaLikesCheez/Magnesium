@testable import Magnesium

extension StandardTorrentFile {
    static func mock(
        index: Int = 0,
        name: String = "Mock",
        size: Int64 = 0,
        progress: Float = 0,
        priority: TorrentPriority = .normal
    ) -> Self {
        .init(index: index, name: name, size: size, progress: progress, priority: priority)
    }
}
