import Combine

enum TorrentDetailEvent {
    case complete
    case alert(Alert, source: PopoverSource?)
    case activities([Activity], torrent: StandardTorrent, source: PopoverSource)
    case moveDownloadFolder(currentPath: String?, subject: PassthroughSubject<String, Never>)
}
