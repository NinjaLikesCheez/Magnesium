import Foundation

/// Lightweight hook for reporting unexpected failures to an external service (e.g. Sentry).
///
/// Packages call ``capture(_:feature:operation:)`` on error paths; the app wires ``handler`` at
/// launch. When unset (tests, previews), reporting is a no-op.
public enum ErrorReporting {
	/// Coarse area of the app where the failure occurred. Serialized as the Sentry `feature` tag.
	public enum Feature: String, Sendable, Hashable {
		case keychain
		case decoding
		case encoding
		case session
		case login
		case client
		case fileImport = "file_import"
		case preferences
	}

	/// Specific action underway when the failure occurred. Serialized as the Sentry `operation` tag.
	public enum Operation: String, Sendable, Hashable {
		case get
		case add
		case delete
		case missingData = "missing_data"
		case serverSettings = "server_settings"
		case qbittorrentClient = "qbittorrent_client"
		case refresh
		case refreshFiles = "refresh_files"
		case addLink = "add_link"
		case paths
		case pause
		case resume
		case remove
		case verify
		case setLabel = "set_label"
		case updateTrackers = "update_trackers"
		case moveDownloadFolder = "move_download_folder"
		case autoRefresh = "auto_refresh"
		case onboardingAddQBittorrent = "onboarding_add_qbittorrent"
		case addQBittorrentServer = "add_qbittorrent_server"
		case loadServers = "load_servers"
		case `import`
		case deleteWithData = "delete_with_data"
		case copyPath = "copy_path"
		case addMagnet = "add_magnet"
		case editServer = "edit_server"
		case authenticate
		case more
	}

	public struct Context: Sendable {
		public var feature: Feature
		public var operation: Operation?

		public init(feature: Feature, operation: Operation? = nil) {
			self.feature = feature
			self.operation = operation
		}
	}

	/// Invoked for each reported error. Set once at app launch; left `nil` in tests.
	nonisolated(unsafe) public static var handler: (@Sendable (any Error, Context) -> Void)?

	/// Reports an error with a coarse feature tag and optional operation for grouping.
	public static func capture(_ error: some Error, feature: Feature, operation: Operation? = nil) {
		handler?(error, Context(feature: feature, operation: operation))
	}
}
