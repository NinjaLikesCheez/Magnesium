import Foundation

struct QBittorrentServerSettings: Equatable, Codable {
	var url: URL
	var username: String
	var password: String
}
