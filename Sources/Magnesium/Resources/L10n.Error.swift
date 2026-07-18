import Foundation

extension L10n {
	enum Error {
		static var failedToPause: String {
			NSLocalizedString("error.failed-to-pause", comment: "Failed to Pause")
		}

		static var failedToGetDownloadFolder: String {
			NSLocalizedString("error.failed-to-get-download-folder", comment: "Failed to Get Download Folder")
		}

		static var failedToResume: String {
			NSLocalizedString("error.failed-to-resume", comment: "Failed to Resume")
		}

		static var failedToRemove: String {
			NSLocalizedString("error.failed-to-remove", comment: "Failed to Remove")
		}

		static var failedToVerifyFiles: String {
			NSLocalizedString("error.failed-to-verify-files", comment: "Failed to Verify Files")
		}

		static var failedToSetLabel: String {
			NSLocalizedString("error.failed-to-set-label", comment: "Failed to Set Label")
		}

		static var failedToUpdateTrackers: String {
			NSLocalizedString("error.failed-to-update-trackers", comment: "Failed to Update Trackers")
		}

		static var failedToRefresh: String {
			NSLocalizedString("error.failed-to-refresh", comment: "Failed to Refresh")
		}

		static var failedToAddServer: String {
			NSLocalizedString("error.failed-to-add-server", comment: "Failed to Add Server")
		}

		static var failedToSaveServer: String {
			NSLocalizedString("error.failed-to-save-server", comment: "Failed to Save Server")
		}

		static var failedToMoveDownloadFolder: String {
			NSLocalizedString("error.failed-to-move-download-folder", comment: "Failed to Move Download Folder")
		}

		static var failedToSetPriority: String {
			NSLocalizedString("error.failed-to-set-priority", comment: "Failed to Set Priority")
		}

		static var failedToDeleteServer: String {
			NSLocalizedString("error.failed-to-delete-server", comment: "Failed to Delete Server")
		}

		static var authenticationFailed: String {
			NSLocalizedString("error.authentication-failed", comment: "Authentication Failed")
		}

		static var unauthenticatedVerifyCredentials: String {
			NSLocalizedString(
				"error.unauthenticated-verify-credentials",
				comment: "Unable to authenticate. Verify that your credentials are correct."
			)
		}

		static var unexpectedServerResponse: String {
			NSLocalizedString(
				"error.unexpected-server-response",
				comment: "The server returned an unexpected response."
			)
		}

		static var serverError: String {
			NSLocalizedString("error.server-error", comment: "The server returned an error.")
		}

		static func serverErrorWithMessage(_ message: String) -> String {
			let format = NSLocalizedString(
				"error.server-error-with-message",
				comment: "The server returned an error: {serverMessage}."
			)
			return .localizedStringWithFormat(format, message)
		}

		static var noSessionID: String {
			NSLocalizedString("error.no-session-id", comment: "Unable to retrieve TorrentSession ID.")
		}

		static func unexpectedStatusCode(_ statusCode: Int) -> String {
			let format = NSLocalizedString(
				"error.unexpected-status-code",
				comment: "The server returned an unexpected status code ({statusCode})."
			)
			return .localizedStringWithFormat(format, statusCode)
		}

		static var invalidURL: String {
			NSLocalizedString("error.invalid-url", comment: "Invalid URL")
		}

		static var invalidURLMessage: String {
			NSLocalizedString(
				"error.invalid-url-message",
				comment: "That URL doesn't appear to be valid."
			)
		}

		static var corruptServerSettingsMessage: String {
			NSLocalizedString(
				"error.corrupt-server-settings-message",
				comment: "The server settings could not be read."
			)
		}

		static var noServersMessage: String {
			NSLocalizedString("error.no-servers-message", comment: "There are no servers.")
		}

		static var unableToAddTorrent: String {
			NSLocalizedString("error.unable-to-add-torrent", comment: "Unable to Add Torrent")
		}

		static var failedToAddTorrent: String {
			NSLocalizedString("error.failed-to-add-torrent", comment: "Failed to Add Torrent")
		}

		static var torrentAlreadyInSession: String {
			NSLocalizedString("error.torrent-already-in-session", comment: "Torrent already in session")
		}

		static var unconnected: String {
			NSLocalizedString("error.unconnected", comment: "There is no host connected to the deluge daemon")
		}

		static var conflict: String {
			// TODO: pass an message through based on the API call to get a better message here...
			NSLocalizedString("error.conflict", comment: "Server was conflicted")
		}

		static var failedToDoAction: String {
			// TODO: get a better error for this too...
			NSLocalizedString("error.failed-to-do-action", comment: "Failed to do action")
		}
	}
}
