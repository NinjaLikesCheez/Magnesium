import Foundation

extension L10n.Screen {
    enum Settings {
        static var title: String {
            NSLocalizedString("screen.settings.title", comment: "Settings")
        }

        static var serversSection: String {
            NSLocalizedString("screen.settings.servers-section", comment: "Servers")
        }

        static var generalSection: String {
            NSLocalizedString("screen.settings.general-section", comment: "General")
        }

        static var currentServer: String {
            NSLocalizedString("screen.settings.current-server", comment: "Current Server")
        }
    }
}
