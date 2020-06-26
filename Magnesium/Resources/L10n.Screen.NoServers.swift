import Foundation

extension L10n.Screen {
    enum NoServers {
        static var header: String {
            NSLocalizedString("screens.no-servers.header", comment: "No Servers")
        }

        static var message: String {
            NSLocalizedString(
                "screens.no-servers.message",
                comment: "You'll need to add a server before you can start using Magnesium."
            )
        }
    }
}
