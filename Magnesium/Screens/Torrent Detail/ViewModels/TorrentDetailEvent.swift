import Combine
import MVVMModels

enum TorrentDetailEvent {
    case complete
    case alert(Alert)
    case activities([Activity], torrent: StandardTorrent, source: PopoverSource)
    case moveDownloadFolder(currentPath: String?, subject: PassthroughSubject<String, Never>)
}
