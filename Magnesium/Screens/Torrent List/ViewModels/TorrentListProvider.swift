import CommonModels
import UIKit

protocol TorrentListProvider: AnyObject {
    func detailViewModelForItem(at index: Int) -> AnyTorrentDetailViewModel?
    func contextMenuForItem(at index: Int) -> UIMenu?
    func leadingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> SwipeActionsConfiguration?
    func trailingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> SwipeActionsConfiguration?
}
