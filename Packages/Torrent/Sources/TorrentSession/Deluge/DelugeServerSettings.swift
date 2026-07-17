import Foundation

public struct DelugeServerSettings: Equatable, Codable, Sendable {
	public let url: URL

	public init(url: URL) {
		self.url = url
	}
}
