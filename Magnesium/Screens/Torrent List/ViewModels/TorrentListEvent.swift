import Combine

enum TorrentListEvent {
    case alert(Alert)
    case activities([Activity], torrents: [StandardTorrent], source: PopoverSource)
    case add(source: PopoverSource, linkSubject: PassthroughSubject<String, Never>)
    case filter(source: PopoverSource, labels: CurrentValueSubject<[StandardLabel], Never>)
    case detail(viewModel: AnyTorrentDetailViewModel)
    case settings
    case moveDownloadFolder(currentPath: String?, subject: PassthroughSubject<String, Never>)
    case torrentsUpdated(hashes: [String])
}
