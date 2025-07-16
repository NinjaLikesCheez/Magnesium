import Foundation

/// Protocol defining the interface for session management
protocol SessionProtocol: AnyObject {
	/// initialize a session
	init(_ preferences: Preferences)
	
	/// The currently selected server
	var server: Server? { get }

	/// The action implementation for torrent operations
	var actionImplementation: any TorrentClientActing { get }

	/// Sets the current server
	/// - Parameter server: The server to set
	/// - Throws: Session.Error if the server configuration is invalid
	func setServer(_ server: Server) throws(Session.Error)

	/// Resets the session, clearing the current server
	func reset()
}
