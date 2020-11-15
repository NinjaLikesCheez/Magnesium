import Foundation

struct StandardTorrent: Equatable {
    var dateAdded: Date
    var downloaded: Int64
    var downloadPath: String
    var downloadRate: Int64
    var eta: TimeInterval
    var hash: String
    var label: String
    var name: String
    var peers: Int
    var progress: Float
    var seeds: Int
    var size: Int64
    var state: TorrentState
    var totalPeers: Int
    var totalSeeds: Int
    var trackers: [String]
    var uploaded: Int64
    var uploadRate: Int64
}

extension StandardTorrent {
    var ratio: Double {
        Double(uploaded) / Double(downloaded)
    }

    var isActive: Bool {
        state == .downloading || state == .seeding
    }

    var localizedSpeed: String {
        if state == .downloading {
            let download = Formatters.bytes.string(fromByteCount: downloadRate)
            let upload = Formatters.bytes.string(fromByteCount: uploadRate)
            return L10n.Torrent.downloadUploadSpeed(downloadSpeed: download, uploadSpeed: upload)
        } else if state == .seeding {
            return L10n.Torrent.uploadSpeed(Formatters.bytes.string(fromByteCount: uploadRate))
        } else {
            return ""
        }
    }

    var localizedProgress: String {
        L10n.Torrent.progress(
            downloaded: Formatters.bytes.string(fromByteCount: downloaded),
            size: Formatters.bytes.string(fromByteCount: size),
            progress: Formatters.percentage.string(for: progress) ?? ""
        )
    }

    var formattedETA: String {
        eta > 0 ? Formatters.eta.string(from: eta) ?? "" : L10n.Common.infinity
    }

    func formattedRatio(precision: Int = 1) -> String {
        guard !ratio.isInfinite, !ratio.isNaN else { return L10n.Common.infinity }
        return Formatters.number(precision: precision).string(for: ratio) ?? ""
    }

    var localizedRatioOrETA: String {
        if state == .downloading {
            return formattedETA
        } else {
            return L10n.Torrent.ratio(formattedRatio())
        }
    }
}
