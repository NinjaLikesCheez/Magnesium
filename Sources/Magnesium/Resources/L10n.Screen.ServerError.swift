import Foundation

extension L10n.Screen {
	enum ServerError {
		static var header: String {
			NSLocalizedString("screen.server-error.header", comment: "Unable to Load Server")
		}

		static var message: String {
			// swiftformat:disable indent
			NSLocalizedString(
				"screen.server-error.message",
				comment: """
					Sorry, your server settings were unable to be read. Please try re-entering your server information.
					"""
			)
			// swiftformat:enable indent
		}
	}
}
