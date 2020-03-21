import CommonModels

enum TorrentDetailViewEvent {
    case appear
    case disappear
    case refresh
    case moreOptions(source: PopoverSource)
    case pause
    case resume
    case remove(source: PopoverSource)
}
