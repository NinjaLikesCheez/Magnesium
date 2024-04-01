import CommonModels
import Foundation

enum TorrentDetailViewEvent {
    case appeared
    case disappeared
    case refresh
    case moreOptionsSelected(source: PopoverSource)
    case pauseSelected
    case resumeSelected
    case removeSelected(source: PopoverSource)
    case copyDownloadFolderPathSelected
    case editSectionSelected(TorrentDetailSectionType)
    case doneEditingSelected
    case multiSelectUpdated(indexPaths: [IndexPath])
    case setFilePrioritySelected(indexPaths: [IndexPath], source: PopoverSource)
}
