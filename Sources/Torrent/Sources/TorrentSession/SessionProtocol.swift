import Foundation
import TorrentPreferences

/// Protocol defining the interface for session management
public protocol SessionProtocol: AnyObject {
	/// initialize a session
	init(_ preferences: TorrentPreferences)

	/// The currently selected server
	var server: TorrentServer? { get }

	/// The client for torrent operations
	var client: any TorrentClient { get }

	/// Sets the current server
	/// - Parameter server: The server to set
	/// - Throws: Session.Error if the server configuration is invalid
	func setServer(_ server: TorrentServer) throws(Session.Error)

	/// Resets the session, clearing the current server
	func reset()
}
