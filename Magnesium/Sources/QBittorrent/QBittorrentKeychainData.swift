import Foundation
import QBittorrent

struct QBittorrentKeychainData: Equatable, Codable {
	var url: URL
	var username: String
	var password: String
	var basicAuthentication: BasicAuthentication?
}
