import Combine
import CommonModels

struct TorrentListViewValues {
    var showAddButton: Bool = true
    var showFilterButton: Bool = true
    var title: UIPublisher<String>
    var items: UIPublisher<[TorrentListItem]>
    var isLoading: UIPublisher<Bool>
    var isEditing: UIPublisher<Bool>
    var hasActiveFilters: UIPublisher<Bool>
    var editActionsEnabled: UIPublisher<Bool>
    var status: UIPublisher<String>
    var detailViewModel: (TorrentListItem) -> AnyTorrentDetailViewModel?
    var contextMenu: (TorrentListItem) -> Menu?
    var leadingSwipeActionsConfiguration: (TorrentListItem, PopoverSource) -> SwipeActionsConfiguration?
    var trailingSwipeActionsConfiguration: (TorrentListItem, PopoverSource) -> SwipeActionsConfiguration?
}
