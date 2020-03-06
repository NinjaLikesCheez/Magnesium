@testable import Magnesium

struct MockTorrentFile: StandardTorrentFile {
    var index: Int = 0
    var name: String = ""
    var size: Int64 = 0
    var progress: Float = 0
}
