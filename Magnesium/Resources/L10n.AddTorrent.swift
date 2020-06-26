import Foundation

extension L10n {
    enum AddTorrent {
        static func addToServer(serverName: String) -> String {
            let format = NSLocalizedString("add-torrent.add-to-server", comment: "Add to {serverName}")
            return .localizedStringWithFormat(format, serverName)
        }

        static var addMethodPrompt: String {
            NSLocalizedString("add-torrent.add-method-prompt", comment: "How would you like to add the torrent?")
        }

        static var addLink: String {
            NSLocalizedString("add-torrent.add-link", comment: "Add Link")
        }

        static var addFile: String {
            NSLocalizedString("add-torrent.add-file", comment: "Add File")
        }

        static var enterURL: String {
            NSLocalizedString("add-torrent.enter-url", comment: "Enter a URL")
        }

        static var addLinkHint: String {
            NSLocalizedString(
                "add-torrent.add-link-hint",
                comment: "This can be either a link to a torrent or a magnet link."
            )
        }
    }
}
