import Foundation

extension L10n {
    enum Server {
        static var deluge: String {
            NSLocalizedString("server.deluge", comment: "Deluge")
        }

        static var transmission: String {
            NSLocalizedString("server.transmission", comment: "Transmission")
        }

        static var qbittorrent: String {
            NSLocalizedString("server.qbittorrent", comment: "qBittorrent")
        }
    }
}
