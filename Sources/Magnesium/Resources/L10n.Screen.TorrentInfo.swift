import Foundation

extension L10n.Screen {
    enum TorrentInfo {
        static var title: String {
            NSLocalizedString("screen.torrent-info.title", comment: "Info")
        }

        static var informationSection: String {
            NSLocalizedString("screen.torrent-info.information-section", comment: "Information")
        }

        static var trackersSection: String {
            NSLocalizedString("screen.torrent-info.trackers-section", comment: "Trackers")
        }

        static var filesSection: String {
            NSLocalizedString("screen.torrent-info.files-section", comment: "Files")
        }

        static var size: String {
            NSLocalizedString("screen.torrent-info.size", comment: "Size")
        }

        static var downloadSpeed: String {
            NSLocalizedString("screen.torrent-info.download-speed", comment: "Download Speed")
        }

        static var uploadSpeed: String {
            NSLocalizedString("screen.torrent-info.upload-speed", comment: "Upload Speed")
        }

        static var downloaded: String {
            NSLocalizedString("screen.torrent-info.downloaded", comment: "Downloaded")
        }

        static var uploaded: String {
            NSLocalizedString("screen.torrent-info.uploaded", comment: "Uploaded")
        }

        static var eta: String {
            NSLocalizedString("screen.torrent-info.eta", comment: "ETA")
        }

        static var ratio: String {
            NSLocalizedString("screen.torrent-info.ratio", comment: "Ratio")
        }

        static var peers: String {
            NSLocalizedString("screen.torrent-info.peers", comment: "Peers")
        }

        static var seeds: String {
            NSLocalizedString("screen.torrent-info.seeds", comment: "Seeds")
        }

        static var downloadFolder: String {
            NSLocalizedString("screen.torrent-info.download-folder", comment: "Download Folder")
        }
    }
}
