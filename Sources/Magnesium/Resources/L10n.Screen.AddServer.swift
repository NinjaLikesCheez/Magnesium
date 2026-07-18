import Foundation

extension L10n.Screen {
	enum AddServer {
		static var title: String {
			NSLocalizedString("screen.add-server.title", comment: "Add Server")
		}

		static var invalidServerURL: String {
			NSLocalizedString(
				"screen.add-server.invalid-server-url",
				comment: "The server URL is invalid. Ensure the URL begins with \"http://\" or \"https://\"."
			)
		}
	}
}
