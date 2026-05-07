import Foundation
import TorrentPreferences

/// Protocol defining the interface for session management
@MainActor
public protocol TorrentSessionProtocol: AnyObject {
	/// initialize a session
	init(_ preferences: TorrentPreferences)

	/// The currently selected server
	var server: TorrentServer? { get }

	/// The client for torrent operations
	var client: any TorrentClient { get }

	/// Sets the current server
	/// - Parameter server: The server to set
	/// - Throws: TorrentSession.Error if the server configuration is invalid
	func setServer(_ server: TorrentServer) throws(TorrentSession.Error)

	/// Resets the session, clearing the current server
	func reset()
}
