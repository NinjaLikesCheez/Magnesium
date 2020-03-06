import CryptoKit
import Foundation
@testable import Magnesium

struct MockTorrent: StandardTorrent, Equatable {
    static func createHash() -> String {
        let data = UUID().uuidString.data(using: .utf8)!
        let hashed = Insecure.SHA1.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    var hash = Self.createHash()
    var name = ""
    var standardState: TorrentState = .downloading
    var dateAdded = Date()
    var downloadRate: Int64 = 0
    var uploadRate: Int64 = 0
    var eta: TimeInterval = 0
    var progress: Float = 0
    var downloaded: Int64 = 0
    var uploaded: Int64 = 0
    var size: Int64 = 0
    var seeds: Int = 0
    var totalSeeds: Int = 0
    var peers: Int = 0
    var totalPeers: Int = 0
    var trackerStrings: [String] = []
    var label = ""
    var downloadPath: String = ""
}
