import Foundation

extension L10n.Screen {
	enum EditServer {
		static var title: String {
			NSLocalizedString("screen.edit-server.title", comment: "Edit Server")
		}

		static var serverName: String {
			NSLocalizedString("screen.edit-server.server-name", comment: "name")
		}

		static var serverURL: String {
			NSLocalizedString("screen.edit-server.server-url", comment: "server")
		}

		static var password: String {
			NSLocalizedString("screen.edit-server.password", comment: "password")
		}

		static var basicAuthenticationUsername: String {
			NSLocalizedString("screen.edit-server.basic-auth-username", comment: "username")
		}

		static var basicAuthenticationPassword: String {
			NSLocalizedString("screen.edit-server.basic-auth-password", comment: "password")
		}

		static var passwordPlaceholder: String {
			NSLocalizedString(
				"screen.edit-server.password-placeholder",
				comment: "password"
			)
		}

		static var optionalPasswordPlaceholder: String {
			NSLocalizedString(
				"screen.edit-server.optional-password-placeholder",
				comment: "password (optional)"
			)
		}

		static var username: String {
			NSLocalizedString("screen.edit-server.username", comment: "username")
		}

		static var optionalUsernamePlaceholder: String {
			NSLocalizedString("screen.edit-server.optional-username-placeholder", comment: "user (optional)")
		}

		static var deleteServerConfirmation: String {
			NSLocalizedString(
				"screen.edit-server.delete-server-confirmation",
				comment: "Are you sure you want to delete this server?"
			)
		}
	}
}
