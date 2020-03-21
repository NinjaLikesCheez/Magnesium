import Combine

enum TorrentDetailViewModelEvent {
    case complete
    case alert(Alert)
    case activities([Activity], torrent: StandardTorrent, source: PopoverSource)
    case moveDownloadFolder(currentPath: String?, subject: PassthroughSubject<String, Never>)
}
